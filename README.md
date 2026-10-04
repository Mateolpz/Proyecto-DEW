# 🚚 FoodCourt Express

Domicilios de los restaurantes del centro comercial para sus empleados.

```
Proyecto-DEW/
├── APP/            Frontend (HTML + CSS + JS) que consume la API
├── backend/        API REST con Node.js + Express + MySQL
│   ├── server.js
│   ├── uploads/    fotos subidas (se crea sola, no va al repo)
│   └── .env.example
├── database/       schema.sql · seed.sql · pruebas.sql
└── docs/           diagrama entidad-relación
```

## Cómo correrlo

1. **Base de datos** (MySQL 8): en Workbench ejecuta `database/schema.sql` y luego `database/seed.sql`.
2. **Backend** (en una terminal, dentro de la carpeta `backend`):
   ```bash
   copy .env.example .env     # en Mac/Linux: cp .env.example .env
   npm install
   npm start
   ```
   Abre `.env` y pon tu contraseña de MySQL en `DB_PASSWORD`.
3. Abre **http://localhost:3000**. Deja la terminal abierta mientras usas la app.

Al arrancar, el backend cambia los `HASH_PENDIENTE` del seed por hashes bcrypt reales.
Todos los usuarios de prueba quedan con la clave **1234**:

| Rol | Correo |
|---|---|
| Empleado | `ana@centro.com`, `julian@centro.com` |
| Restaurante | `burger@foodcourt.co`, `pizza@foodcourt.co`, `criollo@foodcourt.co` |
| Domiciliario | `andres@foodcourt.co`, `camila@foodcourt.co` |
| Admin | `admin@foodcourt.co` |

Para probar el flujo completo abre 3 ventanas (una en incógnito): el empleado pide, el restaurante prepara, asigna domiciliario y despacha, y el domiciliario entrega con foto.

## Endpoints

| Método | Ruta | Quién | Descripción |
|---|---|---|---|
| POST | `/api/login` | todos | `{correo, contrasenia}` → `{token, usuario}` |
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
