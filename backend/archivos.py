"""Persistencia dual: el archivo físico va a disco (backend/uploads/<carpeta>/) y sus metadatos a la tabla `archivos`.

Reglas que cumple (rúbrica 5.0):
  - Nombre único en disco (UUID) + extensión derivada del contenido real, nunca del nombre que manda el usuario.
  - Valida extensión, tipo MIME declarado, firma real del archivo (magic bytes) y peso máximo.
  - Guarda los metadatos completos tal como los define schema.sql (nombre original, peso, ruta, fecha, autor).
  - Atómico: si falla la BD se borra el archivo; si falla el disco no se crea el registro. Sin enlaces rotos.
  - Descarga/visualización inmediata con control de permisos (los carnés y fotos de perfil no son públicos).

Uso desde otros routers (productos, entrega de pedidos):
    from archivos import guardar_archivo
    a = guardar_archivo(conn, archivo, "foto_producto", u["id"],
                        vincular=lambda id_a: ejecutar(conn, "UPDATE productos SET id_fotoFK=%s WHERE id_producto=%s", (id_a, id_prod)))
"""
import os
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import FileResponse

from db import ejecutar, get_db, todos, transaccion, uno
from seguridad import ErrorApi, usuario_actual

router = APIRouter(prefix="/api", tags=["Archivos"])

BASE = Path(__file__).resolve().parent / "uploads"
LIMITE_BYTES = 5 * 1024 * 1024  # 5 MB

# categoría (ENUM de la tabla) -> subcarpeta en disco
CARPETAS = {
    "foto_producto": "productos",
    "logo_restaurante": "logos",
    "foto_perfil": "perfiles",
    "carne_empleado": "carnes",
    "evidencia_entrega": "entregas",
}
# Carpetas que se sirven como estáticas (/uploads/...). carnes y perfiles NO: solo por el endpoint con login.
CARPETAS_PUBLICAS = ["productos", "logos", "entregas"]

# Categorías que se pueden subir con el endpoint genérico y quién puede hacerlo
SUBIDA_GENERICA = {
    "foto_perfil": {"empleado", "restaurante", "domiciliario", "admin"},
    "carne_empleado": {"empleado"},
    "logo_restaurante": {"restaurante"},
}

EXTENSIONES = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".webp": "image/webp"}
EXT_POR_MIME = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}


def crear_carpetas():
    """Llamar al arrancar la app (main.py)."""
    for sub in CARPETAS.values():
        (BASE / sub).mkdir(parents=True, exist_ok=True)


def _mime_real(datos: bytes) -> str | None:
    """Detecta el tipo por los primeros bytes, no por lo que diga el cliente."""
    if datos.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if datos.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"
    if datos[:4] == b"RIFF" and datos[8:12] == b"WEBP":
        return "image/webp"
    return None


def guardar_archivo(conn, archivo: UploadFile, categoria: str, id_autor: int, vincular=None) -> dict:
    """Valida, guarda en disco e inserta los metadatos. `vincular(id_archivo)` se ejecuta en la misma transacción."""
    if categoria not in CARPETAS:
        raise ErrorApi(400, "Categoría de archivo no válida")
    if archivo is None or not archivo.filename:
        raise ErrorApi(400, "Selecciona un archivo")

    original = os.path.basename(archivo.filename)[:255]
    ext_original = os.path.splitext(original)[1].lower()
    if ext_original not in EXTENSIONES:
        raise ErrorApi(400, "Solo se permiten imágenes JPG, PNG o WebP")

    contenido = archivo.file.read(LIMITE_BYTES + 1)
    if not contenido:
        raise ErrorApi(400, "El archivo está vacío")
    if len(contenido) > LIMITE_BYTES:
        raise ErrorApi(413, f"El archivo supera el máximo de {LIMITE_BYTES // (1024 * 1024)} MB")

    mime = _mime_real(contenido)
    if mime is None or EXTENSIONES[ext_original] != mime or (archivo.content_type and archivo.content_type != mime):
        raise ErrorApi(400, "El contenido no coincide con una imagen JPG, PNG o WebP válida")

    nombre = f"{uuid.uuid4()}{EXT_POR_MIME[mime]}"
    sub = CARPETAS[categoria]
    carpeta = BASE / sub
    carpeta.mkdir(parents=True, exist_ok=True)
    ruta_disco = carpeta / nombre
    ruta_url = f"uploads/{sub}/{nombre}"

    ruta_disco.write_bytes(contenido)          # 1) disco
    try:
        with transaccion(conn):                # 2) base de datos (si falla, se borra el archivo)
            c = ejecutar(
                conn,
                """INSERT INTO archivos (nombre_original, nombre_almacenado, tipo_mime, peso_bytes,
                                         ruta_url, categoria, id_autorFK)
                   VALUES (%s, %s, %s, %s, %s, %s, %s)""",
                (original, nombre, mime, len(contenido), ruta_url, categoria, id_autor),
            )
            id_archivo = c.lastrowid
            if vincular:
                vincular(id_archivo)
    except Exception:
        ruta_disco.unlink(missing_ok=True)
        raise
    return {"id": id_archivo, "nombre_original": original, "tipo_mime": mime, "peso_bytes": len(contenido),
            "categoria": categoria, "ruta": ruta_url}


def _vinculo(conn, categoria: str, u: dict):
    """Cada categoría actualiza la fila que usa el archivo (perfil, carné o logo)."""
    if categoria == "foto_perfil":
        return lambda ida: ejecutar(conn, "UPDATE usuarios SET id_foto_perfilFK = %s WHERE id_usuario = %s", (ida, u["id"]))
    if categoria == "carne_empleado":
        return lambda ida: ejecutar(conn, "UPDATE empleados SET id_carneFK = %s WHERE id_usuarioFK = %s", (ida, u["id"]))
    if categoria == "logo_restaurante":
        return lambda ida: ejecutar(conn, "UPDATE restaurantes SET id_logoFK = %s WHERE id_administradorFK = %s", (ida, u["id"]))
    return None


@router.post("/archivos", status_code=201)
def subir(categoria: str = Form(...), archivo: UploadFile = File(...), u=Depends(usuario_actual), conn=Depends(get_db)):
    """Subida genérica: foto de perfil, carné del empleado o logo del restaurante."""
    if categoria not in SUBIDA_GENERICA:
        raise ErrorApi(400, "Esta categoría se sube desde su propia pantalla (producto o entrega)")
    if u["rol"] not in SUBIDA_GENERICA[categoria]:
        raise ErrorApi(403, "Tu rol no puede subir este tipo de archivo")
    return guardar_archivo(conn, archivo, categoria, u["id"], vincular=_vinculo(conn, categoria, u))


@router.get("/archivos")
def mis_archivos(u=Depends(usuario_actual), conn=Depends(get_db)):
    """Historial/consulta: archivos que subió el usuario (el admin ve todos)."""
    donde, params = ("", ()) if u["rol"] == "admin" else ("WHERE id_autorFK = %s", (u["id"],))
    return todos(
        conn,
        f"""SELECT id_archivo AS id, nombre_original, tipo_mime, peso_bytes, categoria, fecha_subida, id_autorFK AS autor
            FROM archivos {donde} ORDER BY fecha_subida DESC, id_archivo DESC""",
        params,
    )


@router.get("/archivos/{id_archivo}/descargar")
def descargar(id_archivo: int, ver: int = 0, u=Depends(usuario_actual), conn=Depends(get_db)):
    """ver=1 la muestra en el navegador; sin ver, la descarga."""
    a = uno(conn, "SELECT * FROM archivos WHERE id_archivo = %s", (id_archivo,))
    if not a:
        raise ErrorApi(404, "El archivo no existe")
    if u["rol"] != "admin" and a["id_autorFK"] != u["id"]:
        raise ErrorApi(403, "No tienes permiso para ver este archivo")
    ruta = (BASE.parent / a["ruta_url"]).resolve()
    if BASE.resolve() not in ruta.parents or not ruta.is_file():
        raise ErrorApi(404, "El archivo ya no está en el servidor")
    return FileResponse(ruta, media_type=a["tipo_mime"], filename=a["nombre_original"],
                        content_disposition_type="inline" if ver else "attachment")


@router.delete("/archivos/{id_archivo}")
def borrar(id_archivo: int, u=Depends(usuario_actual), conn=Depends(get_db)):
    a = uno(conn, "SELECT * FROM archivos WHERE id_archivo = %s", (id_archivo,))
    if not a:
        raise ErrorApi(404, "El archivo no existe")
    if u["rol"] != "admin" and a["id_autorFK"] != u["id"]:
        raise ErrorApi(403, "No puedes borrar este archivo")
    with transaccion(conn):  # las FK tienen ON DELETE SET NULL, nada queda apuntando a un archivo borrado
        ejecutar(conn, "DELETE FROM archivos WHERE id_archivo = %s", (id_archivo,))
    (BASE.parent / a["ruta_url"]).unlink(missing_ok=True)
    return {"ok": True}