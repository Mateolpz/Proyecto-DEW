"""Conexión a MySQL y utilidades para consultas."""
import os
import ssl as ssl_lib
from contextlib import contextmanager

import pymysql
from pymysql.cursors import DictCursor


def _ssl():
    """En la nube (Aiven, etc.) la conexión debe ir cifrada: DB_SSL=true en las variables de entorno."""
    if os.getenv("DB_SSL", "false").lower() not in ("1", "true", "si", "sí"):
        return None
    ca = os.getenv("DB_SSL_CA")  # opcional: ruta al certificado CA del proveedor
    return {"ca": ca} if ca else {"check_hostname": False, "verify_mode": ssl_lib.CERT_NONE}


def conectar():
    return pymysql.connect(
        ssl=_ssl(),
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "foodcourt"),
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=True,
    )


def get_db():
    """Dependencia de FastAPI: abre una conexión por petición y la cierra al final."""
    conn = conectar()
    try:
        yield conn
    finally:
        conn.close()


def uno(conn, sql, params=()):
    with conn.cursor() as c:
        c.execute(sql, params)
        return c.fetchone()


def todos(conn, sql, params=()):
    with conn.cursor() as c:
        c.execute(sql, params)
        return c.fetchall()


def ejecutar(conn, sql, params=()):
    """Ejecuta INSERT/UPDATE/DELETE y devuelve el cursor (lastrowid, rowcount)."""
    with conn.cursor() as c:
        c.execute(sql, params)
        return c


@contextmanager
def transaccion(conn):
    conn.begin()
    try:
        yield
        conn.commit()
    except Exception:
        conn.rollback()
        raise
