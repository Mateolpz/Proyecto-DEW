"""Persistencia dual: el archivo va a backend/uploads/<carpeta>/ y sus metadatos a la tabla archivos."""
import os
import uuid
from pathlib import Path

from fastapi import UploadFile

from db import ejecutar
from seguridad import ErrorApi

UPLOADS = Path(__file__).parent / "uploads"
CARPETAS = {
    "foto_producto": "productos",
    "evidencia_entrega": "entregas",
    "logo_restaurante": "logos",
    "foto_perfil": "perfiles",
    "carne_empleado": "carnes",
}
TIPOS = {"image/jpeg", "image/png", "image/webp"}
MAX_BYTES = 5 * 1024 * 1024


async def leer_imagen(archivo: UploadFile | None) -> tuple[UploadFile, bytes] | None:
    if archivo is None or not archivo.filename:
        return None
    if archivo.content_type not in TIPOS:
        raise ErrorApi(400, "Solo se permiten imágenes JPG, PNG o WEBP")
    contenido = await archivo.read()
    if len(contenido) > MAX_BYTES:
        raise ErrorApi(400, "La imagen pesa más de 5 MB")
    if not contenido:
        raise ErrorApi(400, "La imagen está vacía")
    return archivo, contenido


def guardar_archivo(conn, imagen: tuple[UploadFile, bytes], categoria: str, id_autor: int) -> int:
    archivo, contenido = imagen
    carpeta = CARPETAS[categoria]
    nombre = f"{uuid.uuid4()}{os.path.splitext(archivo.filename)[1].lower()}"
    destino = UPLOADS / carpeta
    destino.mkdir(parents=True, exist_ok=True)
    (destino / nombre).write_bytes(contenido)
    c = ejecutar(conn,
        """INSERT INTO archivos (nombre_original, nombre_almacenado, tipo_mime, peso_bytes, ruta_url, categoria, id_autorFK)
           VALUES (%s, %s, %s, %s, %s, %s, %s)""",
        (archivo.filename, nombre, archivo.content_type, len(contenido), f"uploads/{carpeta}/{nombre}", categoria, id_autor))
    return c.lastrowid
