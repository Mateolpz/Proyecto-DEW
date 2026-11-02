<<<<<<< HEAD
# Proyecto-DEW

FoodCourt Express
Sistema de Delivery de Comida para Empleados de Centro Comercial
Una aplicación web moderna que permite a los empleados de un centro comercial pedir comida de diferentes restaurantes ubicados en el mismo lugar, con seguimiento en tiempo real de entregas.


Problema Identificado
Los empleados del centro comercial pierden tiempo en desplazamientos para comer durante su jornada laboral:
- Tienen que salir de sus zonas de trabajo.
- Esperas largas en las filas de los restaurantes.
- Tiempo limitado en breaks.
- Dificultad para coordinar pedidos en grupo.

Impacto: Menos productividad, estrés laboral, comidas apuradas.

Objetivos Específicos
1. Reducir tiempo de compra: De 20-30 min a 5 min máximo
2. Aumentar comodidad: Pedir desde el escritorio/teléfono
3. Mejorar variedad: Acceso a múltiples restaurantes en un solo lugar
4. Facilitar seguimiento: Saber dónde está el pedido en tiempo real
5. Permitir descuentos: Cupones y promociones especiales para empleados

Alcance Claramente Delimitado
Incluye:
- Catálogo de productos de restaurantes dentro del centro.
- Sistema de pedidos con carrito.
- Aplicación de cupones de descuento.
- Seguimiento en tiempo real del estado del pedido.
- Autenticación de empleados.
- Interface responsive (web y móvil).

NO Incluye (Fuera de alcance)
- Pagos online (se cobra en entrega).
- Entregas fuera del centro comercial.
- Integración con sistemas externos de restaurantes.
- Reservas de mesa.
- Reseñas y calificaciones.

Historias de Usuario Claras
Historia 1: Ana (Empleado en Rush)
"Como empleada del centro comercial quiero pedir comida desde mi escritorio en 5 minutos para poder comer sin dejar mi zona de trabajo durante el break."

Criterios de aceptación:
- Puedo buscar restaurantes disponibles
- Ver menú y agregar items al carrito
- Aplicar cupón de descuento
- Especificar punto de entrega
- Recibir confirmación y estado del pedido

Historia 2: Carlos (Restaurantero)
"Como dueño de Burger House quiero recibir y gestionar pedidos en tiempo real para preparar la comida eficientemente"

Criterios de aceptación:
- Ver nuevos pedidos al instante
- Cambiar estado (Pendiente → Preparando → Listo)
- Notificar cuando está listo
- Ver historial de pedidos del día

Historia 3: Juan (Domiciliario)
Como domiciliario del centro comercial quiero asignarme entregas automáticamente para optimizar mis rutas.

Criterios de aceptación:
- Ver pedidos listos para recoger
- Marcar ruta como asignada
- Actualizar ubicación en tiempo real
- Confirmar entrega

Historia 4: Manager (Admin)
"Como gerente del centro comercial quiero ver reportes de ventas y comportamiento de usuarios para optimizar el servicio"

Criterios de aceptación:
- Ver estadísticas de pedidos por día/semana/mes
- Identificar restaurantes más populares
- Analizar horarios pico
- Generar reportes exportables

Caracteristicas Principales App -> Para empleados clientes
- Catálogo de Restaurantes: Explora los restaurantes disponibles en el centro comercial.
- Filtrado Dinámico: Filtra productos por restaurante.
- Carrito de Compras: Gestiona items, cantidades e incrementa/disminuye fácilmente.
- Sistema de Cupones: Aplica códigos de descuento (porcentaje o monto fijo).
- Autenticación: Login seguro con sesión persistente.
- Seguimiento de Pedido: Visualiza el estado en tiempo real (Pendiente → Preparando → En camino → Entregado).
- Punto de Entrega: Especifica dónde recibirás tu comida.
- Interfaz Responsive: Funciona perfectamente en desktop, tablet y móvil.
- Dark Mode: Tema oscuro automático según preferencia del sistema.

Restricciones de Negocio Implementadas
- Un restaurante por pedido: No puedes mezclar comida de diferentes restaurantes
- Validación de disponibilidad: Solo muestra productos disponibles
- Aplicación de cupones: Descuentos por porcentaje o cantidad fija

Backend y Persistencia
- API REST: Endpoints para productos, restaurantes, pedidos
- Base de Datos: Persistencia de pedidos, usuarios, cupones
- Autenticación JWT: Seguridad en servidor
- Validaciones en Servidor: Verificación de datos antes de guardar

Paneles Especializados
- Panel Restaurante: Gestionar pedidos en tiempo real
- Panel Domiciliario: Asignar y rastrear entregas
- Panel Admin: Reportes y gestión de usuarios
- Sistema de Calificaciones: Reseñas de pedidos y domiciliarios

Funcionalidades Avanzadas
- Integración de Pagos: PayU, Stripe o similar
- Notificaciones Push: Estado de pedido en tiempo real
- Reportes: Análisis de ventas, comportamiento de usuarios
- Upload de Archivos: Fotos de productos, perfiles

Stack Tecnológico
Frontend 
- HTML5 -> Estructura semántica
- CSS3 -> Estilos con variables CSS
- JavaScript -> Lógica del cliente
- LocalStorage -> Persistencia cliente-side

Backend 
Node.js -> Runtime
Express.js -> Framework web
MySQL -> Base de datos
JWT -> Autenticación
bcryptjs -> Hash de contraseñas
Multer -> Upload de archivos

Herramientas
- Git & GitHub -> Control de versiones
- MySQL Workbench -> Gestión de BD
- Postman -> Testing de APIs
=======
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
| POST | `/api/logout` | logueado | Cierra la sesión e invalida el token |
| POST | `/api/mis-productos` | restaurante | Crea un producto (201) |
| DELETE | `/api/productos/:id` | restaurante | Elimina un producto sin pedidos (409 si tiene pedidos) |

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
>>>>>>> origin/Mateo
