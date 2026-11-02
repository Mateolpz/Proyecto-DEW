# 🚚 FoodCourt Express

Domicilios de los restaurantes del centro comercial para sus empleados.

```
Proyecto-DEW/
├── APP/            Frontend (HTML + CSS + JS) que consume la API
├── backend/        API REST con Python + FastAPI + MySQL
│   ├── main.py         arranque, /health, errores y archivos estáticos
│   ├── db.py           conexión a MySQL
│   ├── seguridad.py    bcrypt, JWT y roles
│   ├── archivos.py     subida de fotos (persistencia dual)
│   ├── rutas/          auth.py · catalogo.py · pedidos.py
│   ├── uploads/        fotos subidas (se crea sola, no va al repo)
│   ├── requirements.txt
│   └── .env.example
├── database/       schema.sql · seed.sql · pruebas.sql
└── docs/           diagrama entidad-relación
```

## Cómo correrlo

1. **Base de datos** (MySQL 8): en Workbench ejecuta `database/schema.sql` y luego `database/seed.sql`.
2. **Backend** (Python 3.10 o superior; en una terminal, dentro de la carpeta `backend`):
   ```bash
   python -m venv .venv
   .venv\Scripts\activate          # en Mac/Linux: source .venv/bin/activate
   pip install -r requirements.txt
   copy .env.example .env           # en Mac/Linux: cp .env.example .env
   python main.py
   ```
   Abre `.env` y pon tu contraseña de MySQL en `DB_PASSWORD`.
3. Revisa **http://localhost:3000/health**: debe decir `"base_de_datos": "conectada"`.
4. Abre **http://localhost:3000** para usar la app, o **http://localhost:3000/docs** para probar la API.
   Deja la terminal abierta mientras usas la app.

Al arrancar, el backend cambia los `HASH_PENDIENTE` del seed por hashes bcrypt reales.
Todos los usuarios de prueba quedan con la clave **1234**:

| Rol | Correo |
|---|---|
| Empleado | `ana@centro.com`, `julian@centro.com` |
| Restaurante | `burger@foodcourt.co`, `pizza@foodcourt.co`, `criollo@foodcourt.co` |
| Domiciliario | `andres@foodcourt.co`, `camila@foodcourt.co` |
| Admin | `admin@foodcourt.co` |

Para probar el flujo completo abre 3 ventanas (una en incógnito): el empleado pide, el restaurante prepara, asigna domiciliario y despacha, y el domiciliario entrega con foto.

Cualquier empleado nuevo puede crear su cuenta desde **Regístrate** en la ventana de inicio de sesión.

## Endpoints

| Método | Ruta | Quién | Descripción |
|---|---|---|---|
| GET | `/health` | público | Prueba la conexión a MySQL |
| POST | `/api/login` | todos | `{correo, contrasenia}` → `{token, usuario}` |
| POST | `/api/registro` | público | Crea un empleado e inicia sesión |
| GET | `/api/centros` | público | Centros comerciales (para el registro) |
| GET | `/api/restaurantes` | público | Restaurantes activos |
| GET | `/api/productos?restaurante=id` | público | Productos con su foto |
| GET | `/api/cupones` | empleado | Cupones asignados sin usar |
| GET | `/api/cupones/validar?codigo=&restaurante=` | empleado | Valida un cupón |
| POST | `/api/pedidos` | empleado | `{items:[{id,cantidad}], punto_entrega, cupon?}` |
| GET | `/api/pedidos?activos=1` | todos | Pedidos según el rol |
| GET | `/api/pedidos/:id` | todos | Detalle, productos e historial de estados |
| PATCH | `/api/pedidos/:id/estado` | según rol | `{estado}` |
| GET | `/api/domiciliarios/disponibles` | restaurante | Domiciliarios libres |
| PATCH | `/api/pedidos/:id/domiciliario` | restaurante | `{id_domiciliario}` |
| POST | `/api/pedidos/:id/entregar` | domiciliario | `multipart`, campo `archivo` (foto opcional) |
| GET | `/api/mis-productos` | restaurante | Productos de su restaurante |
| PATCH | `/api/productos/:id` | restaurante | `{disponible?, precio?}` |
| POST | `/api/productos/:id/foto` | restaurante | `multipart`, campo `archivo` |

Los errores siempre responden `{"error": "...", "campos": {"campo": "mensaje"}}`; el frontend muestra cada mensaje debajo de su campo.
Las rutas protegidas usan `Authorization: Bearer <token>` (JWT, 8 h). El admin tiene todos los permisos.

## Reglas de negocio

Las garantizan los triggers de `schema.sql`; el backend además las valida antes para dar mensajes claros:

- Un pedido = un solo restaurante, sin productos agotados.
- Solo empleados verificados pueden pedir.
- Cupón vigente, asignado al empleado, sin usar y válido en ese restaurante.
- Flujo: `pendiente → preparando → en_camino → entregado` (se puede cancelar antes de salir).
- No sale en camino sin domiciliario, y solo se asignan domiciliarios disponibles.
- Precios y descuentos se calculan con los datos de la BD, no con los del navegador.
- **Persistencia dual:** las fotos se guardan en `backend/uploads/` y sus metadatos en la tabla `archivos`.
