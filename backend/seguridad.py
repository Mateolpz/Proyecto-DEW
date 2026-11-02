"""Errores de la API, contraseñas (bcrypt), tokens (JWT) y control de roles."""
import os
import uuid
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import Depends, Header

from db import ejecutar, get_db, uno

DURACION_SESION = timedelta(hours=8)


class ErrorApi(Exception):
    def __init__(self, codigo: int, mensaje: str, campos: dict | None = None):
        super().__init__(mensaje)
        self.codigo, self.mensaje, self.campos = codigo, mensaje, campos


def secreto():
    return os.getenv("JWT_SECRET", "cambia-este-secreto")


def hashear(clave: str) -> str:
    return bcrypt.hashpw(clave.encode(), bcrypt.gensalt(10)).decode()


def verificar_clave(clave: str, hash_guardado: str) -> bool:
    try:
        return bcrypt.checkpw(clave.encode(), hash_guardado.encode())
    except ValueError:  # p. ej. 'HASH_PENDIENTE' antes de arrancar el servidor
        return False


def crear_token(usuario: dict, conn) -> str:
    """Crea una sesión en la BD y devuelve un JWT que apunta a ella (claim jti)."""
    id_sesion = str(uuid.uuid4())
    ejecutar(conn, "INSERT INTO sesiones (id_sesion, id_usuarioFK) VALUES (%s, %s)", (id_sesion, usuario["id"]))
    datos = {**usuario, "jti": id_sesion, "exp": datetime.now(timezone.utc) + DURACION_SESION}
    return jwt.encode(datos, secreto(), algorithm="HS256")


def usuario_actual(authorization: str = Header(default=""), conn=Depends(get_db)):
    token = authorization.replace("Bearer ", "")
    try:
        u = jwt.decode(token, secreto(), algorithms=["HS256"])
    except jwt.PyJWTError:
        raise ErrorApi(401, "Inicia sesión para continuar")
    # El token puede seguir vigente, pero la sesión pudo cerrarse o el usuario desactivarse
    estado = uno(conn,
        """SELECT s.cerrada, u.activo FROM sesiones s
             JOIN usuarios u ON u.id_usuario = s.id_usuarioFK
            WHERE s.id_sesion = %s""", (u.get("jti"),))
    if not estado or estado["cerrada"]:
        raise ErrorApi(401, "Tu sesión terminó, inicia sesión de nuevo")
    if not estado["activo"]:
        raise ErrorApi(401, "Tu usuario está desactivado")
    return u


def requiere(*roles):
    """Dependencia que exige sesión y uno de los roles indicados (el admin pasa siempre)."""
    def dependencia(u: dict = Depends(usuario_actual)):
        if roles and u["rol"] not in roles and u["rol"] != "admin":
            raise ErrorApi(403, "Tu usuario no tiene permiso para esto")
        return u
    return dependencia