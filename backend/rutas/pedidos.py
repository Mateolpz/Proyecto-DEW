"""Cupones, pedidos, domiciliarios y entregas."""
from fastapi import APIRouter, Depends, File, UploadFile
from pydantic import BaseModel

from archivos import guardar_archivo, leer_imagen
from db import ejecutar, get_db, todos, transaccion, uno
from seguridad import ErrorApi, requiere

router = APIRouter(prefix="/api", tags=["Pedidos"])

# ---------------------------------------------------------------------
# Cupones (empleado)
# ---------------------------------------------------------------------
def descuento_de(c: dict, subtotal: float) -> float:
    valor = float(c["valor"])
    return round(subtotal * valor / 100) if c["tipo"] == "porcentaje" else min(valor, subtotal)


def cupon_del_empleado(conn, codigo: str, id_empleado: int, id_restaurante: int | None):
    """Cupón asignado al empleado, sin usar, vigente y válido para ese restaurante."""
    c = uno(conn,
        """SELECT c.*, ec.usado, CURDATE() BETWEEN c.fecha_inicio AND c.fecha_fin AS vigente
             FROM cupones c
             LEFT JOIN empleado_cupon ec ON ec.id_cuponFK = c.id_cupon AND ec.id_empleadoFK = %s
            WHERE c.codigo = %s""", (id_empleado, codigo.strip().upper()))
    if not c:
        raise ErrorApi(404, "Ese cupón no existe")
    if c["usado"] is None:
        raise ErrorApi(400, "Ese cupón no está asignado a tu usuario")
    if c["usado"]:
        raise ErrorApi(400, "Ya usaste ese cupón")
    if not c["vigente"]:
        raise ErrorApi(400, "El cupón no está vigente")
    if id_restaurante and c["id_restauranteFK"] and c["id_restauranteFK"] != int(id_restaurante):
        raise ErrorApi(400, "El cupón no es válido en este restaurante")
    return c


@router.get("/cupones")
def mis_cupones(u=Depends(requiere("empleado")), conn=Depends(get_db)):
    return todos(conn,
        """SELECT c.codigo, c.tipo, c.valor, c.condiciones, c.fecha_fin, c.id_restauranteFK AS restaurante
             FROM empleado_cupon ec JOIN cupones c ON c.id_cupon = ec.id_cuponFK
            WHERE ec.id_empleadoFK = %s AND ec.usado = FALSE AND CURDATE() BETWEEN c.fecha_inicio AND c.fecha_fin""",
        (u["id"],))


@router.get("/cupones/validar")
def validar_cupon(codigo: str = "", restaurante: int | None = None,
                  u=Depends(requiere("empleado")), conn=Depends(get_db)):
    c = cupon_del_empleado(conn, codigo, u["id"], restaurante)
    return {"codigo": c["codigo"], "tipo": c["tipo"], "valor": c["valor"],
            "condiciones": c["condiciones"], "restaurante": c["id_restauranteFK"]}


# ---------------------------------------------------------------------
# Pedidos
# ---------------------------------------------------------------------
def detalle_pedido(conn, id_pedido: int):
    p = uno(conn,
        """SELECT p.id_pedido AS id, p.id_empleadoFK AS id_empleado, p.id_restauranteFK AS id_restaurante,
                  p.id_domiciliarioFK AS id_domiciliario, r.nombre_restaurante AS restaurante,
                  CONCAT(e.primer_nombre, ' ', e.primer_apellido) AS empleado, e.telefono AS telefono_empleado,
                  CONCAT(d.primer_nombre, ' ', d.primer_apellido) AS domiciliario,
                  DATE_FORMAT(p.fecha_pedido, '%%Y-%%m-%%d %%H:%%i') AS fecha, p.punto_entrega, p.subtotal,
                  p.descuento, p.valor_total AS total, p.estado, p.tiempo_estimado, p.tiempo_real,
                  c.codigo AS cupon, ev.ruta_url AS evidencia
             FROM pedidos p
             JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
             JOIN usuarios e ON e.id_usuario = p.id_empleadoFK
             LEFT JOIN usuarios d ON d.id_usuario = p.id_domiciliarioFK
             LEFT JOIN cupones c ON c.id_cupon = p.id_cuponFK
             LEFT JOIN archivos ev ON ev.id_archivo = p.id_evidenciaFK
            WHERE p.id_pedido = %s""", (id_pedido,))
    if not p:
        return None
    p["items"] = todos(conn,
        """SELECT d.id_productoFK AS id, pr.nombre_producto AS nombre, d.cantidad, d.precio_unitario AS precio, d.subtotal
             FROM detalle_pedidos d JOIN productos pr ON pr.id_producto = d.id_productoFK
            WHERE d.id_pedidoFK = %s""", (id_pedido,))
    p["historial"] = todos(conn,
        """SELECT estado, DATE_FORMAT(fecha_hora, '%%Y-%%m-%%d %%H:%%i:%%s') AS fecha_hora
             FROM historial_estado_pedido WHERE id_pedidoFK = %s ORDER BY id_historial""", (id_pedido,))
    return p


def pedido_permitido(conn, id_pedido: int, u: dict):
    """Devuelve el pedido si el usuario puede verlo/gestionarlo."""
    p = detalle_pedido(conn, id_pedido)
    if p:
        rol = u["rol"]
        if rol == "admin":
            return p
        if rol == "empleado" and p["id_empleado"] == u["id"]:
            return p
        if rol == "domiciliario" and p["id_domiciliario"] == u["id"]:
            return p
        if rol == "restaurante" and uno(conn,
                "SELECT 1 AS ok FROM restaurantes WHERE id_restaurante = %s AND id_administradorFK = %s",
                (p["id_restaurante"], u["id"])):
            return p
    raise ErrorApi(404, "Pedido no encontrado")


class ItemIn(BaseModel):
    id: int
    cantidad: int = 1


class PedidoIn(BaseModel):
    items: list[ItemIn] = []
    punto_entrega: str = ""
    cupon: str | None = None


@router.post("/pedidos", status_code=201)
def crear_pedido(d: PedidoIn, u=Depends(requiere("empleado")), conn=Depends(get_db)):
    if not d.items:
        raise ErrorApi(400, "El pedido está vacío")
    punto = d.punto_entrega.strip()
    if len(punto) < 3:
        raise ErrorApi(400, "Indica el punto de entrega", {"punto_entrega": "Indica dónde te lo llevamos"})

    emp = uno(conn, "SELECT verificado FROM empleados WHERE id_usuarioFK = %s", (u["id"],))
    if not emp:
        raise ErrorApi(403, "Solo los empleados registrados pueden pedir")
    if not emp["verificado"]:
        raise ErrorApi(403, "Tu cuenta de empleado aún no ha sido verificada")

    # Agrupa cantidades por producto (la PK del detalle no permite repetir producto)
    cantidades: dict[int, int] = {}
    for i in d.items:
        if i.cantidad <= 0:
            raise ErrorApi(400, "Cantidad inválida")
        cantidades[i.id] = cantidades.get(i.id, 0) + i.cantidad

    # Los precios salen de la BD, nunca del navegador
    prods = todos(conn, "SELECT * FROM productos WHERE id_producto IN %s", (tuple(cantidades),))
    if len(prods) != len(cantidades):
        raise ErrorApi(400, "Hay productos que no existen")
    agotado = next((p for p in prods if not p["disponible"]), None)
    if agotado:
        raise ErrorApi(409, f"{agotado['nombre_producto']} está agotado")
    restaurantes = {p["id_restauranteFK"] for p in prods}
    if len(restaurantes) > 1:
        raise ErrorApi(400, "Un pedido solo puede ser de un restaurante")
    id_restaurante = restaurantes.pop()

    subtotal = sum(float(p["precio"]) * cantidades[p["id_producto"]] for p in prods)
    c = cupon_del_empleado(conn, d.cupon, u["id"], id_restaurante) if d.cupon else None
    descuento = descuento_de(c, subtotal) if c else 0
    tiempo_estimado = 20 + min(sum(cantidades.values()), 10) * 2  # minutos

    with transaccion(conn):
        cur = ejecutar(conn,
            """INSERT INTO pedidos (id_empleadoFK, id_restauranteFK, id_cuponFK, punto_entrega, subtotal, descuento, tiempo_estimado)
               VALUES (%s, %s, %s, %s, %s, %s, %s)""",
            (u["id"], id_restaurante, c["id_cupon"] if c else None, punto, subtotal, descuento, tiempo_estimado))
        id_pedido = cur.lastrowid
        with conn.cursor() as cur2:
            cur2.executemany(
                "INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (%s, %s, %s, %s)",
                [(id_pedido, p["id_producto"], cantidades[p["id_producto"]], p["precio"]) for p in prods])
    return detalle_pedido(conn, id_pedido)


@router.get("/pedidos")
def listar_pedidos(activos: bool = False, u=Depends(requiere()), conn=Depends(get_db)):
    """empleado → los suyos · restaurante → los de su restaurante · domiciliario → los asignados · admin → todos"""
    where, params = [], []
    if u["rol"] == "empleado":
        where.append("p.id_empleadoFK = %s"); params.append(u["id"])
    elif u["rol"] == "domiciliario":
        where.append("p.id_domiciliarioFK = %s"); params.append(u["id"])
    elif u["rol"] == "restaurante":
        where.append("r.id_administradorFK = %s"); params.append(u["id"])
    if activos:
        where.append("p.estado NOT IN ('entregado', 'cancelado')")
    filas = todos(conn,
        f"""SELECT p.id_pedido AS id FROM pedidos p JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
            {"WHERE " + " AND ".join(where) if where else ""}
            ORDER BY p.fecha_pedido DESC, p.id_pedido DESC LIMIT 50""", tuple(params))
    return [detalle_pedido(conn, f["id"]) for f in filas]


@router.get("/pedidos/{id_pedido}")
def ver_pedido(id_pedido: int, u=Depends(requiere()), conn=Depends(get_db)):
    return pedido_permitido(conn, id_pedido, u)


# Quién puede poner cada estado (el trigger de la BD valida además el orden del flujo)
PERMISOS_ESTADO = {
    "restaurante": {"preparando", "en_camino", "cancelado"},
    "empleado": {"cancelado"},
    "domiciliario": {"entregado"},
    "admin": {"preparando", "en_camino", "entregado", "cancelado"},
}


class EstadoIn(BaseModel):
    estado: str


@router.patch("/pedidos/{id_pedido}/estado")
def cambiar_estado(id_pedido: int, d: EstadoIn, u=Depends(requiere()), conn=Depends(get_db)):
    p = pedido_permitido(conn, id_pedido, u)
    if d.estado not in PERMISOS_ESTADO[u["rol"]]:
        raise ErrorApi(403, "No puedes poner el pedido en ese estado")
    if u["rol"] == "empleado" and p["estado"] != "pendiente":
        raise ErrorApi(400, "Solo puedes cancelar antes de que lo empiecen a preparar")
    ejecutar(conn,
        """UPDATE pedidos SET estado = %s,
                  tiempo_real = IF(%s = 'entregado', TIMESTAMPDIFF(MINUTE, fecha_pedido, NOW()), tiempo_real)
            WHERE id_pedido = %s""", (d.estado, d.estado, id_pedido))
    return detalle_pedido(conn, id_pedido)


@router.get("/domiciliarios/disponibles")
def domiciliarios_disponibles(u=Depends(requiere("restaurante")), conn=Depends(get_db)):
    return todos(conn,
        """SELECT d.id_usuarioFK AS id, CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre, d.tipo_vehiculo
             FROM domiciliarios d JOIN usuarios u ON u.id_usuario = d.id_usuarioFK
            WHERE d.disponible = TRUE AND u.activo = TRUE ORDER BY u.primer_nombre""")


class DomiciliarioIn(BaseModel):
    id_domiciliario: int


@router.patch("/pedidos/{id_pedido}/domiciliario")
def asignar_domiciliario(id_pedido: int, d: DomiciliarioIn, u=Depends(requiere("restaurante")), conn=Depends(get_db)):
    p = pedido_permitido(conn, id_pedido, u)
    if p["estado"] not in ("pendiente", "preparando"):
        raise ErrorApi(400, "Solo se asigna domiciliario antes de que salga el pedido")
    if p["id_domiciliario"]:
        raise ErrorApi(400, "Este pedido ya tiene domiciliario")
    ejecutar(conn, "UPDATE pedidos SET id_domiciliarioFK = %s WHERE id_pedido = %s", (d.id_domiciliario, id_pedido))
    return detalle_pedido(conn, id_pedido)


@router.post("/pedidos/{id_pedido}/entregar")
async def entregar(id_pedido: int, archivo: UploadFile | None = File(None),
                   u=Depends(requiere("domiciliario")), conn=Depends(get_db)):
    """El domiciliario marca el pedido como entregado, con foto de evidencia opcional."""
    p = pedido_permitido(conn, id_pedido, u)
    if p["estado"] != "en_camino":
        raise ErrorApi(400, "El pedido no está en camino")
    imagen = await leer_imagen(archivo)
    with transaccion(conn):
        id_evidencia = guardar_archivo(conn, imagen, "evidencia_entrega", u["id"]) if imagen else None
        ejecutar(conn,
            """UPDATE pedidos SET estado = 'entregado', id_evidenciaFK = %s,
                      tiempo_real = TIMESTAMPDIFF(MINUTE, fecha_pedido, NOW())
                WHERE id_pedido = %s""", (id_evidencia, id_pedido))
    return detalle_pedido(conn, id_pedido)
