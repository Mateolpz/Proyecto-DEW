"""Restaurantes y productos (público) + gestión de productos (restaurante)."""
from fastapi import APIRouter, Depends, File, UploadFile
from pydantic import BaseModel

from archivos import guardar_archivo, leer_imagen
from db import ejecutar, get_db, todos, transaccion, uno
from seguridad import ErrorApi, requiere

router = APIRouter(prefix="/api", tags=["Catálogo"])

SELECT_PRODUCTO = """SELECT p.id_producto AS id, p.id_restauranteFK AS r, p.nombre_producto AS nombre, p.descripcion,
                            p.precio, p.disponible, a.ruta_url AS foto
                       FROM productos p
                       JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
                       LEFT JOIN archivos a ON a.id_archivo = p.id_fotoFK"""


@router.get("/restaurantes")
def restaurantes(conn=Depends(get_db)):
    return todos(conn,
        """SELECT r.id_restaurante AS id, r.nombre_restaurante AS nombre, r.categoria, r.local, r.piso,
                  TIME_FORMAT(r.hora_apertura, '%%H:%%i') AS apertura, TIME_FORMAT(r.hora_cierre, '%%H:%%i') AS cierre,
                  a.ruta_url AS logo
             FROM restaurantes r LEFT JOIN archivos a ON a.id_archivo = r.id_logoFK
            WHERE r.activo = TRUE ORDER BY r.id_restaurante""")


@router.get("/productos")
def productos(restaurante: int | None = None, conn=Depends(get_db)):
    sql = SELECT_PRODUCTO + " WHERE r.activo = TRUE"
    if restaurante:
        return todos(conn, sql + " AND p.id_restauranteFK = %s ORDER BY p.id_producto", (restaurante,))
    return todos(conn, sql + " ORDER BY p.id_producto")


def producto_propio(conn, id_producto: int, u: dict) -> dict:
    p = uno(conn,
        """SELECT p.* FROM productos p JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
            WHERE p.id_producto = %s AND (r.id_administradorFK = %s OR %s = 'admin')""",
        (id_producto, u["id"], u["rol"]))
    if not p:
        raise ErrorApi(404, "Producto no encontrado")
    return p


@router.get("/mis-productos")
def mis_productos(u=Depends(requiere("restaurante")), conn=Depends(get_db)):
    return todos(conn, SELECT_PRODUCTO + " WHERE r.id_administradorFK = %s OR %s = 'admin' ORDER BY p.id_producto",
                 (u["id"], u["rol"]))


class ProductoIn(BaseModel):
    disponible: bool | None = None
    precio: float | None = None


@router.patch("/productos/{id_producto}")
def editar_producto(id_producto: int, d: ProductoIn, u=Depends(requiere("restaurante")), conn=Depends(get_db)):
    p = producto_propio(conn, id_producto, u)
    if d.precio is not None and d.precio <= 0:
        raise ErrorApi(400, "El precio debe ser mayor a 0")
    ejecutar(conn, "UPDATE productos SET disponible = %s, precio = %s WHERE id_producto = %s",
             (p["disponible"] if d.disponible is None else d.disponible,
              p["precio"] if d.precio is None else d.precio, id_producto))
    return {"ok": True}


@router.post("/productos/{id_producto}/foto", status_code=201)
async def subir_foto(id_producto: int, archivo: UploadFile | None = File(None),
                     u=Depends(requiere("restaurante")), conn=Depends(get_db)):
    producto_propio(conn, id_producto, u)
    imagen = await leer_imagen(archivo)
    if not imagen:
        raise ErrorApi(400, "Adjunta una imagen")
    with transaccion(conn):
        id_foto = guardar_archivo(conn, imagen, "foto_producto", u["id"])
        ejecutar(conn, "UPDATE productos SET id_fotoFK = %s WHERE id_producto = %s", (id_foto, id_producto))
    return {"foto": uno(conn, "SELECT ruta_url FROM archivos WHERE id_archivo = %s", (id_foto,))["ruta_url"]}
