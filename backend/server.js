// =====================================================================
// FoodCourt Express · API REST (Node + Express + MySQL)
// Trabaja sobre database/schema.sql. Las reglas de negocio las garantizan
// los triggers de la BD; aquí se validan antes para dar mensajes claros.
// =====================================================================
require("dotenv").config();
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const express = require("express");
const cors = require("cors");
const multer = require("multer");
const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || "cambia-este-secreto";
const CLAVE_DEMO = process.env.CLAVE_DEMO || "1234";
const UPLOADS = path.join(__dirname, "uploads");
const FRONTEND = path.join(__dirname, "..", "APP");

const db = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "foodcourt",
  charset: "utf8mb4",
  decimalNumbers: true,
  dateStrings: true,
});

const app = express();
app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(UPLOADS));
app.get("/", (_req, res) => res.sendFile(path.join(FRONTEND, "Index.html")));
app.use(express.static(FRONTEND));

class ErrorApi extends Error { constructor(code, msg) { super(msg); this.code = code; } }
const falla = (code, msg) => { throw new ErrorApi(code, msg); };

// ---------------------------------------------------------------------
// Autenticación y roles
// ---------------------------------------------------------------------
function auth(...roles) {
  return (req, _res, next) => {
    const token = (req.headers.authorization || "").replace("Bearer ", "");
    try { req.usuario = jwt.verify(token, JWT_SECRET); }
    catch { return next(new ErrorApi(401, "Inicia sesión para continuar")); }
    if (roles.length && !roles.includes(req.usuario.rol) && req.usuario.rol !== "admin")
      return next(new ErrorApi(403, "Tu usuario no tiene permiso para esto"));
    next();
  };
}

app.post("/api/login", async (req, res) => {
  const { correo, contrasenia } = req.body || {};
  if (!correo || !contrasenia) falla(400, "Correo y contraseña son obligatorios");
  const [[u]] = await db.query("SELECT * FROM usuarios WHERE correo = ?", [String(correo).trim().toLowerCase()]);
  if (!u || !(await bcrypt.compare(contrasenia, u.contrasenia_hash))) falla(401, "Correo o contraseña incorrectos");
  if (!u.activo) falla(403, "Tu usuario está desactivado");
  const usuario = { id: u.id_usuario, nombre: u.primer_nombre, apellido: u.primer_apellido, correo: u.correo, rol: u.rol };
  res.json({ token: jwt.sign(usuario, JWT_SECRET, { expiresIn: "8h" }), usuario });
});

// ---------------------------------------------------------------------
// Archivos (persistencia dual): el archivo va a backend/uploads/<carpeta>/
// y sus metadatos a la tabla archivos.
// ---------------------------------------------------------------------
const CARPETAS = { foto_producto: "productos", evidencia_entrega: "entregas", logo_restaurante: "logos", foto_perfil: "perfiles", carne_empleado: "carnes" };
const subir = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, f, cb) => /^image\/(jpeg|png|webp)$/.test(f.mimetype)
    ? cb(null, true) : cb(new ErrorApi(400, "Solo se permiten imágenes JPG, PNG o WEBP")),
}).single("archivo");
const recibirArchivo = (req, res, next) => subir(req, res, (e) =>
  next(e && e.code === "LIMIT_FILE_SIZE" ? new ErrorApi(400, "La imagen pesa más de 5 MB") : e));

async function guardarArchivo(conn, file, categoria, idAutor) {
  const carpeta = CARPETAS[categoria];
  const nombre = crypto.randomUUID() + path.extname(file.originalname || "").toLowerCase();
  fs.mkdirSync(path.join(UPLOADS, carpeta), { recursive: true });
  fs.writeFileSync(path.join(UPLOADS, carpeta, nombre), file.buffer);
  const [r] = await conn.query(
    `INSERT INTO archivos (nombre_original, nombre_almacenado, tipo_mime, peso_bytes, ruta_url, categoria, id_autorFK)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [file.originalname, nombre, file.mimetype, file.size, `uploads/${carpeta}/${nombre}`, categoria, idAutor]);
  return r.insertId;
}

// ---------------------------------------------------------------------
// Catálogo (público)
// ---------------------------------------------------------------------
app.get("/api/restaurantes", async (_req, res) => {
  const [rows] = await db.query(
    `SELECT r.id_restaurante AS id, r.nombre_restaurante AS nombre, r.categoria, r.local, r.piso,
            TIME_FORMAT(r.hora_apertura, '%H:%i') AS apertura, TIME_FORMAT(r.hora_cierre, '%H:%i') AS cierre,
            a.ruta_url AS logo
       FROM restaurantes r LEFT JOIN archivos a ON a.id_archivo = r.id_logoFK
      WHERE r.activo = TRUE ORDER BY r.id_restaurante`);
  res.json(rows);
});

app.get("/api/productos", async (req, res) => {
  const filtro = Number(req.query.restaurante) || null;
  const [rows] = await db.query(
    `SELECT p.id_producto AS id, p.id_restauranteFK AS r, p.nombre_producto AS nombre, p.descripcion,
            p.precio, p.disponible, a.ruta_url AS foto
       FROM productos p
       JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK AND r.activo = TRUE
       LEFT JOIN archivos a ON a.id_archivo = p.id_fotoFK
      ${filtro ? "WHERE p.id_restauranteFK = ?" : ""} ORDER BY p.id_producto`, filtro ? [filtro] : []);
  res.json(rows);
});

// ---------------------------------------------------------------------
// Cupones (empleado)
// ---------------------------------------------------------------------
const descuentoDe = (c, sub) =>
  c.tipo === "porcentaje" ? Math.round(sub * c.valor / 100) : Math.min(c.valor, sub);

// Cupón asignado al empleado, sin usar, vigente y válido para ese restaurante
async function cuponDelEmpleado(codigo, idEmpleado, idRestaurante) {
  const [[c]] = await db.query(
    `SELECT c.*, ec.usado FROM cupones c
       LEFT JOIN empleado_cupon ec ON ec.id_cuponFK = c.id_cupon AND ec.id_empleadoFK = ?
      WHERE c.codigo = ?`, [idEmpleado, String(codigo).trim().toUpperCase()]);
  if (!c) falla(404, "Ese cupón no existe");
  if (c.usado === null) falla(400, "Ese cupón no está asignado a tu usuario");
  if (c.usado) falla(400, "Ya usaste ese cupón");
  const hoy = new Date().toLocaleDateString("en-CA");
  if (hoy < c.fecha_inicio || hoy > c.fecha_fin) falla(400, "El cupón no está vigente");
  if (idRestaurante && c.id_restauranteFK && c.id_restauranteFK !== Number(idRestaurante))
    falla(400, "El cupón no es válido en este restaurante");
  return c;
}

app.get("/api/cupones", auth("empleado"), async (req, res) => {
  const [rows] = await db.query(
    `SELECT c.codigo, c.tipo, c.valor, c.condiciones, c.fecha_fin, c.id_restauranteFK AS restaurante
       FROM empleado_cupon ec JOIN cupones c ON c.id_cupon = ec.id_cuponFK
      WHERE ec.id_empleadoFK = ? AND ec.usado = FALSE AND CURDATE() BETWEEN c.fecha_inicio AND c.fecha_fin`,
    [req.usuario.id]);
  res.json(rows);
});

app.get("/api/cupones/validar", auth("empleado"), async (req, res) => {
  const c = await cuponDelEmpleado(req.query.codigo || "", req.usuario.id, req.query.restaurante);
  res.json({ codigo: c.codigo, tipo: c.tipo, valor: c.valor, condiciones: c.condiciones, restaurante: c.id_restauranteFK });
});

// ---------------------------------------------------------------------
// Pedidos
// ---------------------------------------------------------------------
async function detallePedido(id) {
  const [[p]] = await db.query(
    `SELECT p.id_pedido AS id, p.id_empleadoFK AS id_empleado, p.id_restauranteFK AS id_restaurante,
            p.id_domiciliarioFK AS id_domiciliario, r.nombre_restaurante AS restaurante,
            CONCAT(e.primer_nombre, ' ', e.primer_apellido) AS empleado, e.telefono AS telefono_empleado,
            CONCAT(d.primer_nombre, ' ', d.primer_apellido) AS domiciliario,
            p.fecha_pedido AS fecha, p.punto_entrega, p.subtotal, p.descuento, p.valor_total AS total,
            p.estado, p.tiempo_estimado, p.tiempo_real, c.codigo AS cupon, ev.ruta_url AS evidencia
       FROM pedidos p
       JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
       JOIN usuarios e ON e.id_usuario = p.id_empleadoFK
       LEFT JOIN usuarios d ON d.id_usuario = p.id_domiciliarioFK
       LEFT JOIN cupones c ON c.id_cupon = p.id_cuponFK
       LEFT JOIN archivos ev ON ev.id_archivo = p.id_evidenciaFK
      WHERE p.id_pedido = ?`, [id]);
  if (!p) return null;
  const [items] = await db.query(
    `SELECT d.id_productoFK AS id, pr.nombre_producto AS nombre, d.cantidad, d.precio_unitario AS precio, d.subtotal
       FROM detalle_pedidos d JOIN productos pr ON pr.id_producto = d.id_productoFK
      WHERE d.id_pedidoFK = ?`, [id]);
  const [historial] = await db.query(
    "SELECT estado, fecha_hora FROM historial_estado_pedido WHERE id_pedidoFK = ? ORDER BY id_historial", [id]);
  return { ...p, items, historial };
}

// ¿El usuario puede ver/gestionar este pedido?
async function pedidoPermitido(id, u) {
  const p = await detallePedido(id);
  if (!p) falla(404, "Pedido no encontrado");
  if (u.rol === "admin") return p;
  if (u.rol === "empleado" && p.id_empleado === u.id) return p;
  if (u.rol === "domiciliario" && p.id_domiciliario === u.id) return p;
  if (u.rol === "restaurante") {
    const [[r]] = await db.query("SELECT 1 FROM restaurantes WHERE id_restaurante = ? AND id_administradorFK = ?", [p.id_restaurante, u.id]);
    if (r) return p;
  }
  falla(404, "Pedido no encontrado");
}

// Crear pedido (empleado verificado)
app.post("/api/pedidos", auth("empleado"), async (req, res) => {
  const { items, punto_entrega, cupon } = req.body || {};
  if (!Array.isArray(items) || !items.length) falla(400, "El pedido está vacío");
  if (!punto_entrega || !String(punto_entrega).trim()) falla(400, "Indica el punto de entrega");

  const [[emp]] = await db.query("SELECT verificado FROM empleados WHERE id_usuarioFK = ?", [req.usuario.id]);
  if (!emp) falla(403, "Solo los empleados registrados pueden pedir");
  if (!emp.verificado) falla(403, "Tu cuenta de empleado aún no ha sido verificada");

  // Agrupa cantidades por producto (la PK del detalle no permite repetir producto)
  const cantidades = new Map();
  for (const i of items) {
    const id = Number(i.id), q = Math.floor(Number(i.cantidad));
    if (!id || !(q > 0)) falla(400, "Cantidad inválida");
    cantidades.set(id, (cantidades.get(id) || 0) + q);
  }
  // Los precios salen de la BD, nunca del navegador
  const [prods] = await db.query("SELECT * FROM productos WHERE id_producto IN (?)", [[...cantidades.keys()]]);
  if (prods.length !== cantidades.size) falla(400, "Hay productos que no existen");
  const agotado = prods.find((p) => !p.disponible);
  if (agotado) falla(409, `${agotado.nombre_producto} está agotado`);
  const restaurantes = new Set(prods.map((p) => p.id_restauranteFK));
  if (restaurantes.size > 1) falla(400, "Un pedido solo puede ser de un restaurante");
  const idRestaurante = [...restaurantes][0];

  const subtotal = prods.reduce((s, p) => s + p.precio * cantidades.get(p.id_producto), 0);
  const c = cupon ? await cuponDelEmpleado(cupon, req.usuario.id, idRestaurante) : null;
  const descuento = c ? descuentoDe(c, subtotal) : 0;
  const unidades = [...cantidades.values()].reduce((a, b) => a + b, 0);
  const tiempoEstimado = 20 + Math.min(unidades, 10) * 2;   // minutos

  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();
    const [ins] = await conn.query(
      `INSERT INTO pedidos (id_empleadoFK, id_restauranteFK, id_cuponFK, punto_entrega, subtotal, descuento, tiempo_estimado)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [req.usuario.id, idRestaurante, c ? c.id_cupon : null, String(punto_entrega).trim(), subtotal, descuento, tiempoEstimado]);
    await conn.query(
      "INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES ?",
      [prods.map((p) => [ins.insertId, p.id_producto, cantidades.get(p.id_producto), p.precio])]);
    await conn.commit();
    res.status(201).json(await detallePedido(ins.insertId));
  } catch (e) { await conn.rollback(); throw e; }
  finally { conn.release(); }
});

// Lista de pedidos según el rol:
//  empleado → los suyos · restaurante → los de su restaurante · domiciliario → los asignados · admin → todos
// ?activos=1 deja solo los que no están entregados ni cancelados
app.get("/api/pedidos", auth(), async (req, res) => {
  const u = req.usuario;
  const where = [], params = [];
  if (u.rol === "empleado") { where.push("p.id_empleadoFK = ?"); params.push(u.id); }
  if (u.rol === "domiciliario") { where.push("p.id_domiciliarioFK = ?"); params.push(u.id); }
  if (u.rol === "restaurante") { where.push("r.id_administradorFK = ?"); params.push(u.id); }
  if (req.query.activos) where.push("p.estado NOT IN ('entregado', 'cancelado')");
  const [rows] = await db.query(
    `SELECT p.id_pedido AS id FROM pedidos p JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
      ${where.length ? "WHERE " + where.join(" AND ") : ""} ORDER BY p.fecha_pedido DESC, p.id_pedido DESC LIMIT 50`, params);
  res.json(await Promise.all(rows.map((r) => detallePedido(r.id))));
});

app.get("/api/pedidos/:id", auth(), async (req, res) => {
  res.json(await pedidoPermitido(Number(req.params.id), req.usuario));
});

// Cambiar estado. Quién puede hacer qué:
//  restaurante: pendiente→preparando, preparando→en_camino, cancelar
//  empleado:    cancelar mientras esté pendiente
//  domiciliario: en_camino→entregado
const PERMISOS_ESTADO = {
  restaurante: ["preparando", "en_camino", "cancelado"],
  empleado: ["cancelado"],
  domiciliario: ["entregado"],
  admin: ["preparando", "en_camino", "entregado", "cancelado"],
};
app.patch("/api/pedidos/:id/estado", auth(), async (req, res) => {
  const { estado } = req.body || {};
  const p = await pedidoPermitido(Number(req.params.id), req.usuario);
  if (!PERMISOS_ESTADO[req.usuario.rol].includes(estado)) falla(403, "No puedes poner el pedido en ese estado");
  if (req.usuario.rol === "empleado" && p.estado !== "pendiente") falla(400, "Solo puedes cancelar antes de que lo empiecen a preparar");
  await db.query(
    `UPDATE pedidos SET estado = ?,
            tiempo_real = IF(? = 'entregado', TIMESTAMPDIFF(MINUTE, fecha_pedido, NOW()), tiempo_real)
      WHERE id_pedido = ?`, [estado, estado, p.id]);   // el trigger valida el flujo
  res.json(await detallePedido(p.id));
});

// Domiciliarios disponibles y asignación (restaurante)
app.get("/api/domiciliarios/disponibles", auth("restaurante"), async (_req, res) => {
  const [rows] = await db.query(
    `SELECT d.id_usuarioFK AS id, CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS nombre, d.tipo_vehiculo
       FROM domiciliarios d JOIN usuarios u ON u.id_usuario = d.id_usuarioFK
      WHERE d.disponible = TRUE AND u.activo = TRUE ORDER BY u.primer_nombre`);
  res.json(rows);
});

app.patch("/api/pedidos/:id/domiciliario", auth("restaurante"), async (req, res) => {
  const p = await pedidoPermitido(Number(req.params.id), req.usuario);
  if (!["pendiente", "preparando"].includes(p.estado)) falla(400, "Solo se asigna domiciliario antes de que salga el pedido");
  if (p.id_domiciliario) falla(400, "Este pedido ya tiene domiciliario");
  await db.query("UPDATE pedidos SET id_domiciliarioFK = ? WHERE id_pedido = ?", [Number(req.body?.id_domiciliario), p.id]);
  res.json(await detallePedido(p.id));
});

// Entrega con foto de evidencia (domiciliario)
app.post("/api/pedidos/:id/entregar", auth("domiciliario"), recibirArchivo, async (req, res) => {
  const p = await pedidoPermitido(Number(req.params.id), req.usuario);
  if (p.estado !== "en_camino") falla(400, "El pedido no está en camino");
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();
    const idEvidencia = req.file ? await guardarArchivo(conn, req.file, "evidencia_entrega", req.usuario.id) : null;
    await conn.query(
      `UPDATE pedidos SET estado = 'entregado', id_evidenciaFK = ?, tiempo_real = TIMESTAMPDIFF(MINUTE, fecha_pedido, NOW())
        WHERE id_pedido = ?`, [idEvidencia, p.id]);
    await conn.commit();
  } catch (e) { await conn.rollback(); throw e; }
  finally { conn.release(); }
  res.json(await detallePedido(p.id));
});

// ---------------------------------------------------------------------
// Gestión de productos (restaurante)
// ---------------------------------------------------------------------
async function productoPropio(id, u) {
  const [[p]] = await db.query(
    `SELECT p.* FROM productos p JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
      WHERE p.id_producto = ? AND (r.id_administradorFK = ? OR ? = 'admin')`, [id, u.id, u.rol]);
  if (!p) falla(404, "Producto no encontrado");
  return p;
}

app.get("/api/mis-productos", auth("restaurante"), async (req, res) => {
  const [rows] = await db.query(
    `SELECT p.id_producto AS id, p.id_restauranteFK AS r, p.nombre_producto AS nombre, p.descripcion,
            p.precio, p.disponible, a.ruta_url AS foto
       FROM productos p JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
       LEFT JOIN archivos a ON a.id_archivo = p.id_fotoFK
      WHERE r.id_administradorFK = ? OR ? = 'admin' ORDER BY p.id_producto`, [req.usuario.id, req.usuario.rol]);
  res.json(rows);
});

app.patch("/api/productos/:id", auth("restaurante"), async (req, res) => {
  const p = await productoPropio(Number(req.params.id), req.usuario);
  const { disponible, precio } = req.body || {};
  if (precio !== undefined && !(Number(precio) > 0)) falla(400, "El precio debe ser mayor a 0");
  await db.query("UPDATE productos SET disponible = ?, precio = ? WHERE id_producto = ?",
    [disponible === undefined ? p.disponible : !!disponible, precio === undefined ? p.precio : Number(precio), p.id_producto]);
  res.json({ ok: true });
});

app.post("/api/productos/:id/foto", auth("restaurante"), recibirArchivo, async (req, res) => {
  const p = await productoPropio(Number(req.params.id), req.usuario);
  if (!req.file) falla(400, "Adjunta una imagen");
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();
    const idFoto = await guardarArchivo(conn, req.file, "foto_producto", req.usuario.id);
    await conn.query("UPDATE productos SET id_fotoFK = ? WHERE id_producto = ?", [idFoto, p.id_producto]);
    await conn.commit();
    const [[a]] = await db.query("SELECT ruta_url FROM archivos WHERE id_archivo = ?", [idFoto]);
    res.status(201).json({ foto: a.ruta_url });
  } catch (e) { await conn.rollback(); throw e; }
  finally { conn.release(); }
});

// ---------------------------------------------------------------------
// Errores
// ---------------------------------------------------------------------
app.use("/api", (_req, _res, next) => next(new ErrorApi(404, "Ruta no encontrada")));
app.use((err, _req, res, _next) => {
  if (err instanceof ErrorApi) return res.status(err.code).json({ error: err.message });
  if (err.sqlState === "45000") return res.status(400).json({ error: err.sqlMessage });   // mensajes de los triggers
  if (err.code === "ER_DUP_ENTRY") return res.status(409).json({ error: "Ese registro ya existe" });
  if (err.code === "ECONNREFUSED" || err.code === "ER_ACCESS_DENIED_ERROR" || err.code === "ER_BAD_DB_ERROR")
    console.error("❌ No se pudo conectar a MySQL. Revisa el archivo .env y que la base foodcourt exista.");
  else console.error(err);
  res.status(500).json({ error: "Error interno del servidor" });
});

// ---------------------------------------------------------------------
// Arranque: el seed trae 'HASH_PENDIENTE'; se reemplaza por bcrypt de CLAVE_DEMO
// ---------------------------------------------------------------------
async function prepararUsuariosDemo() {
  const [r] = await db.query("UPDATE usuarios SET contrasenia_hash = ? WHERE contrasenia_hash = 'HASH_PENDIENTE'",
    [await bcrypt.hash(CLAVE_DEMO, 10)]);
  if (r.affectedRows) console.log(`🔑 ${r.affectedRows} usuarios de prueba quedaron con la contraseña "${CLAVE_DEMO}"`);
}

prepararUsuariosDemo()
  .catch((e) => console.error("❌ No se pudo conectar a MySQL:", e.message, "\n   Revisa backend/.env y ejecuta database/schema.sql y seed.sql"))
  .finally(() => app.listen(PORT, () => console.log(`🚚 FoodCourt Express en http://localhost:${PORT}`)));
