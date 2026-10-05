"""Inicio de sesión y registro de empleados."""
import os
import re

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from db import ejecutar, get_db, todos, transaccion, uno
from seguridad import ErrorApi, crear_token, hashear, verificar_clave

router = APIRouter(prefix="/api", tags=["Sesión"])

CORREO = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
NOMBRE = re.compile(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]{2,100}$")


def datos_sesion(u: dict) -> dict:
    usuario = {"id": u["id_usuario"], "nombre": u["primer_nombre"], "apellido": u["primer_apellido"],
               "correo": u["correo"], "rol": u["rol"]}
    return {"token": crear_token(usuario), "usuario": usuario}


class LoginIn(BaseModel):
    correo: str = ""
    contrasenia: str = ""


@router.post("/login")
def login(datos: LoginIn, conn=Depends(get_db)):
    campos = {}
    if not datos.correo.strip():
        campos["correo"] = "Escribe tu correo"
    if not datos.contrasenia:
        campos["contrasenia"] = "Escribe tu contraseña"
    if campos:
        raise ErrorApi(400, "Completa los campos", campos)
    u = uno(conn, "SELECT * FROM usuarios WHERE correo = %s", (datos.correo.strip().lower(),))
    if not u or not verificar_clave(datos.contrasenia, u["contrasenia_hash"]):
        raise ErrorApi(401, "Correo o contraseña incorrectos")
    if not u["activo"]:
        raise ErrorApi(403, "Tu usuario está desactivado")
    return datos_sesion(u)


@router.get("/centros")
def centros(conn=Depends(get_db)):
    return todos(conn, "SELECT id_centro AS id, nombre, ciudad FROM centros_comerciales ORDER BY nombre")


class RegistroIn(BaseModel):
    primer_nombre: str = ""
    segundo_nombre: str = ""
    primer_apellido: str = ""
    segundo_apellido: str = ""
    documento: str = ""
    telefono: str = ""
    correo: str = ""
    contrasenia: str = ""
    id_centro: int | None = None
    local_trabajo: str = ""


@router.post("/registro", status_code=201)
def registro(d: RegistroIn, conn=Depends(get_db)):
    """Registra un empleado del centro comercial (solo los empleados se registran solos)."""
    d = d.model_copy(update={k: v.strip() for k, v in d.model_dump().items() if isinstance(v, str)})
    correo = d.correo.lower()
    campos = {}
    if not NOMBRE.match(d.primer_nombre):
        campos["primer_nombre"] = "Escribe tu nombre (solo letras)"
    if d.segundo_nombre and not NOMBRE.match(d.segundo_nombre):
        campos["segundo_nombre"] = "Solo letras"
    if not NOMBRE.match(d.primer_apellido):
        campos["primer_apellido"] = "Escribe tu apellido (solo letras)"
    if d.segundo_apellido and not NOMBRE.match(d.segundo_apellido):
        campos["segundo_apellido"] = "Solo letras"
    if not re.fullmatch(r"\d{6,12}", d.documento):
        campos["documento"] = "Entre 6 y 12 números, sin puntos"
    if not re.fullmatch(r"3\d{9}", d.telefono):
        campos["telefono"] = "Celular de 10 dígitos que empiece por 3"
    if not CORREO.match(correo) or len(correo) > 150:
        campos["correo"] = "Escribe un correo válido"
    if len(d.contrasenia) < 8 or not re.search(r"[A-Za-z]", d.contrasenia) or not re.search(r"\d", d.contrasenia):
        campos["contrasenia"] = "Mínimo 8 caracteres, con letras y números"
    if not d.id_centro or not uno(conn, "SELECT 1 AS ok FROM centros_comerciales WHERE id_centro = %s", (d.id_centro,)):
        campos["id_centro"] = "Elige tu centro comercial"
    if not 3 <= len(d.local_trabajo) <= 100:
        campos["local_trabajo"] = "Indica dónde trabajas (ej. Falabella, piso 1)"
    if not campos.get("correo") and uno(conn, "SELECT 1 AS ok FROM usuarios WHERE correo = %s", (correo,)):
        campos["correo"] = "Ya hay una cuenta con este correo"
    if not campos.get("documento") and uno(conn, "SELECT 1 AS ok FROM usuarios WHERE documento = %s", (d.documento,)):
        campos["documento"] = "Ya hay una cuenta con este documento"
    if campos:
        raise ErrorApi(400, "Revisa los campos marcados", campos)

    verificado = os.getenv("VERIFICAR_AUTOMATICO", "true").lower() == "true"
    with transaccion(conn):
        c = ejecutar(conn,
            """INSERT INTO usuarios (primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
                                     documento, telefono, correo, contrasenia_hash, rol)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'empleado')""",
            (d.primer_nombre, d.segundo_nombre or None, d.primer_apellido, d.segundo_apellido or None,
             d.documento, d.telefono, correo, hashear(d.contrasenia)))
        ejecutar(conn,
            "INSERT INTO empleados (id_usuarioFK, id_centroFK, local_trabajo, verificado) VALUES (%s, %s, %s, %s)",
            (c.lastrowid, d.id_centro, d.local_trabajo, verificado))
    return datos_sesion(uno(conn, "SELECT * FROM usuarios WHERE id_usuario = %s", (c.lastrowid,)))
