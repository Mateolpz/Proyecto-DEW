"""
FoodCourt Express · API REST (Python + FastAPI + MySQL)
Trabaja sobre database/schema.sql. Las reglas de negocio las garantizan los
triggers de la BD; aquí se validan antes para dar mensajes claros.

Arrancar:  python main.py      (o: uvicorn main:app --reload --port 3000)
Docs:      http://localhost:3000/docs
"""
import os
from contextlib import asynccontextmanager
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

import pymysql  # noqa: E402
from fastapi import FastAPI, Request  # noqa: E402
from fastapi.exceptions import RequestValidationError  # noqa: E402
from fastapi.middleware.cors import CORSMiddleware  # noqa: E402
from fastapi.responses import FileResponse, JSONResponse  # noqa: E402
from fastapi.staticfiles import StaticFiles  # noqa: E402

from archivos import UPLOADS  # noqa: E402
from db import conectar  # noqa: E402
from rutas import auth, catalogo, pedidos  # noqa: E402
from seguridad import ErrorApi, hashear  # noqa: E402

FRONTEND = Path(__file__).parent.parent / "APP"


def preparar_usuarios_demo():
    """El seed trae 'HASH_PENDIENTE'; se reemplaza por el hash bcrypt de CLAVE_DEMO."""
    clave = os.getenv("CLAVE_DEMO", "1234")
    try:
        conn = conectar()
        with conn.cursor() as c:
            n = c.execute("UPDATE usuarios SET contrasenia_hash = %s WHERE contrasenia_hash = 'HASH_PENDIENTE'",
                          (hashear(clave),))
        conn.close()
        if n:
            print(f'🔑 {n} usuarios de prueba quedaron con la contraseña "{clave}"')
    except pymysql.MySQLError as e:
        print(f"❌ No se pudo conectar a MySQL: {e}\n   Revisa backend/.env y ejecuta database/schema.sql y seed.sql")


@asynccontextmanager
async def ciclo_de_vida(_app):
    preparar_usuarios_demo()
    yield


app = FastAPI(title="FoodCourt Express API", version="1.0.0", lifespan=ciclo_de_vida)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


# ---------------------------------------------------------------------
# Errores: siempre responden {"error": "...", "campos": {...}}
# ---------------------------------------------------------------------
@app.exception_handler(ErrorApi)
async def error_api(_req: Request, e: ErrorApi):
    cuerpo = {"error": e.mensaje}
    if e.campos:
        cuerpo["campos"] = e.campos
    return JSONResponse(cuerpo, status_code=e.codigo)


@app.exception_handler(RequestValidationError)
async def error_validacion(_req: Request, e: RequestValidationError):
    campos = {str(err["loc"][-1]): "Valor inválido" for err in e.errors()}
    return JSONResponse({"error": "Datos inválidos", "campos": campos}, status_code=422)


@app.exception_handler(pymysql.MySQLError)
async def error_mysql(_req: Request, e: pymysql.MySQLError):
    codigo = e.args[0] if e.args else None
    if codigo == 1644:  # SIGNAL SQLSTATE '45000' de los triggers
        return JSONResponse({"error": e.args[1]}, status_code=400)
    if codigo == 1062:
        return JSONResponse({"error": "Ese registro ya existe"}, status_code=409)
    if codigo == 1452:
        return JSONResponse({"error": "Uno de los datos relacionados no existe"}, status_code=400)
    print("❌ Error de MySQL:", e)
    return JSONResponse({"error": "Error con la base de datos"}, status_code=500)


# ---------------------------------------------------------------------
# Salud del servidor: prueba la conexión a MySQL
# ---------------------------------------------------------------------
@app.get("/health", tags=["Salud"])
def health():
    try:
        conn = conectar()
        with conn.cursor() as c:
            c.execute("SELECT VERSION() AS version, DATABASE() AS base, (SELECT COUNT(*) FROM usuarios) AS usuarios")
            info = c.fetchone()
        conn.close()
        return {"estado": "ok", "base_de_datos": "conectada", **info}
    except pymysql.MySQLError as e:
        return JSONResponse({"estado": "error", "base_de_datos": "sin conexión", "detalle": str(e)}, status_code=503)


app.include_router(auth.router)
app.include_router(catalogo.router)
app.include_router(pedidos.router)


@app.api_route("/api/{ruta:path}", methods=["GET", "POST", "PATCH", "PUT", "DELETE"], include_in_schema=False)
def ruta_no_encontrada(ruta: str):
    return JSONResponse({"error": "Ruta no encontrada"}, status_code=404)


# ---------------------------------------------------------------------
# Archivos subidos y frontend (APP/)
# ---------------------------------------------------------------------
UPLOADS.mkdir(exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOADS), name="uploads")


@app.get("/", include_in_schema=False)
def inicio():
    index = next((f for f in FRONTEND.iterdir() if f.name.lower() == "index.html"), None)
    return FileResponse(index) if index else JSONResponse({"error": "No se encontró APP/index.html"}, status_code=404)


app.mount("/", StaticFiles(directory=FRONTEND), name="frontend")


if __name__ == "__main__":
    import uvicorn

    puerto = int(os.getenv("PORT", "3000"))
    print(f"🚚 FoodCourt Express en http://localhost:{puerto}  ·  Docs: http://localhost:{puerto}/docs")
    uvicorn.run("main:app", host="127.0.0.1", port=puerto, reload=True)
