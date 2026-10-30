"""Errores de la API, contraseñas (bcrypt), tokens (JWT) y control de roles."""
import os
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import Depends, Header


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


def crear_token(usuario: dict) -> str:
    datos = {**usuario, "exp": datetime.now(timezone.utc) + timedelta(hours=8)}
    return jwt.encode(datos, secreto(), algorithm="HS256")


def usuario_actual(authorization: str = Header(default="")):
    token = authorization.replace("Bearer ", "")
    try:
        return jwt.decode(token, secreto(), algorithms=["HS256"])
    except jwt.PyJWTError:
        raise ErrorApi(401, "Inicia sesión para continuar")


def requiere(*roles):
    """Dependencia que exige sesión y uno de los roles indicados (el admin pasa siempre)."""
    def dependencia(u: dict = Depends(usuario_actual)):
        if roles and u["rol"] not in roles and u["rol"] != "admin":
            raise ErrorApi(403, "Tu usuario no tiene permiso para esto")
        return u
    return dependencia
