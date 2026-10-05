/* =====================================================================
   FoodCourt Express · Frontend
   Consume la API de backend/server.js. Roles:
   empleado → menú, carrito y seguimiento · restaurante → panel de pedidos y productos
   domiciliario → entregas asignadas · admin → panel del restaurante con todos los pedidos
   ===================================================================== */

/* ====== API ====== */
// Si lo sirve Express (puerto 3000) usa la misma URL; si lo abres directo o con Live Server, apunta al backend local
const SERVIDOR = location.port === "3000" ? "" : "http://localhost:3000";
const API = SERVIDOR + "/api";

async function api(ruta, opciones = {}) {
  const headers = {};
  if (!(opciones.body instanceof FormData)) headers["Content-Type"] = "application/json";
  if (token) headers.Authorization = "Bearer " + token;
  let res;
  try { res = await fetch(API + ruta, { ...opciones, headers }); }
  catch { throw new Error("No hay conexión con el servidor (¿está corriendo npm start en la carpeta backend?)"); }
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && token) cerrarSesion(false);
  if (!res.ok) throw Object.assign(new Error(data.error || "Error del servidor"), { campos: data.campos });
  return data;
}

/* ====== Utilidades ====== */
const $ = (s) => document.querySelector(s);
const money = (n) => "$" + Math.round(n).toLocaleString("es-CO");
const esc = (t) => String(t ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const foto = (ruta) => (ruta ? `${SERVIDOR}/${ruta}` : "");
const EMOJI = { "Hamburguesas": "🍔", "Pizzería": "🍕", "Comida típica": "🍛" };
const emojiDe = (rest) => EMOJI[rest?.categoria] || "🍽️";
const ETIQUETA = { pendiente: "Pendiente", preparando: "En preparación", en_camino: "En camino", entregado: "Entregado", cancelado: "Cancelado" };
const hora = (f) => (f || "").slice(11, 16);
// Imagen con respaldo: si no hay foto o no carga, muestra el emoji
const img = (src, alt, emoji) => src
  ? `<img src="${esc(src)}" alt="${esc(alt)}" loading="lazy" onerror="this.replaceWith('${emoji}')">`
  : emoji;

/* ====== Estado ====== */
let restaurantes = [], productos = [];
let filtro = 0;
let carrito = {};           // {idProducto: cantidad}
let cupon = null;
let token = sessionStorage.getItem("token");
let usuario = JSON.parse(sessionStorage.getItem("usuario") || "null");
const esEmpleado = () => !usuario || usuario.rol === "empleado";

function mostrarVista(id) {
  ["#viewMenu", "#viewStatus", "#viewPanel"].forEach((v) => $(v).classList.toggle("active", v === id));
  if (id !== "#viewStatus") clearInterval(window.timer);
  if (id !== "#viewPanel") clearInterval(window.timerPanel);
  window.scrollTo(0, 0);
}

/* ====== Menú ====== */
async function cargarMenu() {
  $("#grid").innerHTML = `<p class="muted">Cargando menú…</p>`;
  try {
    [restaurantes, productos] = await Promise.all([api("/restaurantes"), api("/productos")]);
    pintarFiltros(); pintarMenu(); pintarCarrito();
  } catch (e) {
    $("#grid").innerHTML = `<p class="error">${esc(e.message)} <button class="btn ghost" id="retry">Reintentar</button></p>`;
    $("#retry").onclick = cargarMenu;
  }
}
function pintarFiltros() {
  const chips = [{ id: 0, nombre: "Todos" }, ...restaurantes];
  $("#filters").innerHTML = chips.map(c =>
    `<button class="chip ${c.id === filtro ? "on" : ""}" data-r="${c.id}">${esc(c.nombre)}</button>`).join("");
}
function pintarMenu() {
  const lista = productos.filter(p => !filtro || p.r === filtro);
  $("#grid").innerHTML = lista.map(p => {
    const r = restaurantes.find(x => x.id === p.r), e = emojiDe(r);
    return `<article class="card ${p.disponible ? "" : "off"}">
      <div class="photo">${img(foto(p.foto), p.nombre, e)}</div>
      <div class="rest-logo" title="${esc(r.nombre)}">${img(foto(r.logo), r.nombre, e)}</div>
      <div class="body">
        <span class="rest-name">${esc(r.nombre)} · Local ${esc(r.local)}</span>
        <h3>${esc(p.nombre)}</h3>
        <p>${esc(p.descripcion)}</p>
        <div class="foot"><span class="price">${money(p.precio)}</span>
          <button class="btn" data-add="${p.id}">${p.disponible ? "Agregar" : "Agotado"}</button></div>
      </div></article>`;
  }).join("") || `<p class="muted">No hay productos para mostrar.</p>`;
}

/* ====== Carrito ====== */
function restauranteDelCarrito() {
  const ids = Object.keys(carrito);
  return ids.length ? productos.find(p => p.id == ids[0]).r : null;
}
function agregar(id) {
  if (!esEmpleado()) return toast("Solo los empleados pueden hacer pedidos");
  const p = productos.find(x => x.id === id);
  const rc = restauranteDelCarrito();
  // Regla de negocio: un pedido = un solo restaurante (también lo validan el backend y la BD)
  if (rc && rc !== p.r) return toast("Tu pedido solo puede ser de un restaurante. Vacía el carrito para cambiar.");
  carrito[id] = (carrito[id] || 0) + 1;
  pintarCarrito(); toast(`${p.nombre} agregado`);
}
function totales() {
  const sub = Object.entries(carrito).reduce((s, [id, q]) => s + productos.find(p => p.id == id).precio * q, 0);
  const aplica = cupon && (!cupon.restaurante || cupon.restaurante === restauranteDelCarrito());
  const desc = !aplica ? 0 : cupon.tipo === "porcentaje" ? Math.round(sub * cupon.valor / 100) : Math.min(cupon.valor, sub);
  return { sub, desc, total: sub - desc };
}
function pintarCarrito() {
  const ids = Object.keys(carrito);
  if (!ids.length && cupon) { cupon = null; $("#couponMsg").textContent = ""; }
  $("#cartCount").textContent = ids.reduce((s, i) => s + carrito[i], 0);
  $("#cartItems").innerHTML = ids.length ? ids.map(id => {
    const p = productos.find(x => x.id == id);
    return `<div class="item"><div><b>${esc(p.nombre)}</b><br><small>${money(p.precio)}</small></div>
      <div class="qty"><button data-dec="${id}">−</button><b>${carrito[id]}</b><button data-inc="${id}">+</button></div></div>`;
  }).join("") : `<p class="muted">Tu carrito está vacío.</p>`;
  const t = totales();
  $("#tSub").textContent = money(t.sub); $("#tDisc").textContent = "-" + money(t.desc); $("#tTotal").textContent = money(t.total);
}
async function abrirCarrito(v) {
  $("#cart").classList.toggle("open", v); $("#overlay").classList.toggle("on", v);
  if (v) pintarMisCupones();
}
// Cupones asignados al empleado (se pueden tocar para aplicarlos)
async function pintarMisCupones() {
  $("#myCoupons").innerHTML = "";
  if (!usuario || usuario.rol !== "empleado") return;
  try {
    const lista = await api("/cupones");
    $("#myCoupons").innerHTML = lista.length ? `<small class="muted">Tus cupones:</small> ` + lista.map(c =>
      `<button class="chip mini" data-cupon="${esc(c.codigo)}" title="${esc(c.condiciones)}">🎟️ ${esc(c.codigo)}</button>`).join("") : "";
  } catch { /* no es crítico */ }
}
async function aplicarCupon(codigo) {
  codigo = codigo.trim();
  if (!codigo) { cupon = null; $("#couponMsg").textContent = ""; return pintarCarrito(); }
  if (!usuario) { toast("Inicia sesión para usar cupones"); return abrirLogin(true); }
  const rc = restauranteDelCarrito();
  try {
    cupon = await api(`/cupones/validar?codigo=${encodeURIComponent(codigo)}${rc ? "&restaurante=" + rc : ""}`);
    $("#couponInput").value = cupon.codigo;
    $("#couponMsg").textContent = `✅ ${cupon.condiciones}`;
  } catch (e) {
    cupon = null; $("#couponMsg").textContent = "❌ " + e.message;
  }
  pintarCarrito();
}

/* ====== Validación de formularios ======
   Cada regla devuelve el mensaje de error, o "" si el valor está bien.
   Los errores se muestran debajo de cada campo (también los que responde el backend). */
const SOLO_LETRAS = /^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]{2,100}$/;
const REGLAS = {
  correo: (v) => !v ? "Escribe tu correo" : !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(v) ? "Escribe un correo válido" : "",
  contrasenia: (v, f) => !v ? "Escribe tu contraseña"
    : f.id === "registroForm" && (v.length < 8 || !/[A-Za-z]/.test(v) || !/\d/.test(v)) ? "Mínimo 8 caracteres, con letras y números" : "",
  confirmar: (v, f) => !v ? "Repite la contraseña" : v !== f.contrasenia.value ? "Las contraseñas no coinciden" : "",
  primer_nombre: (v) => !v ? "Escribe tu nombre" : !SOLO_LETRAS.test(v) ? "Solo letras" : "",
  segundo_nombre: (v) => v && !SOLO_LETRAS.test(v) ? "Solo letras" : "",
  primer_apellido: (v) => !v ? "Escribe tu apellido" : !SOLO_LETRAS.test(v) ? "Solo letras" : "",
  segundo_apellido: (v) => v && !SOLO_LETRAS.test(v) ? "Solo letras" : "",
  documento: (v) => !v ? "Escribe tu documento" : !/^\d{6,12}$/.test(v) ? "Entre 6 y 12 números, sin puntos" : "",
  telefono: (v) => !v ? "Escribe tu celular" : !/^3\d{9}$/.test(v) ? "Celular de 10 dígitos que empiece por 3" : "",
  id_centro: (v) => !v ? "Elige tu centro comercial" : "",
  local_trabajo: (v) => v.length < 3 ? "Indica dónde trabajas (ej. Falabella, piso 1)" : "",
  punto_entrega: (v) => v.length < 3 ? "Indica dónde te lo llevamos (ej. Falabella, piso 1)" : "",
};
function mostrarError(input, mensaje) {
  const campo = input.closest(".field");
  campo.classList.toggle("invalid", !!mensaje);
  campo.classList.toggle("valid", !mensaje && !!input.value.trim());
  input.setAttribute("aria-invalid", mensaje ? "true" : "false");
  campo.querySelector(".field-error").textContent = mensaje || "";
}
function validarCampo(input) {
  const regla = REGLAS[input.name];
  const mensaje = regla ? regla(input.value.trim(), input.form || input.closest("form, aside")) : "";
  mostrarError(input, mensaje);
  return !mensaje;
}
// Valida todos los campos del contenedor; enfoca el primero con error
function validarTodo(contenedor) {
  const inputs = [...contenedor.querySelectorAll("[name]")].filter(i => i.closest(".field"));
  const malos = inputs.filter(i => { i.dataset.tocado = "1"; return !validarCampo(i); });
  if (malos.length) malos[0].focus();
  return !malos.length;
}
// Pinta los errores por campo que devuelve el backend
function erroresDelServidor(contenedor, campos) {
  let primero = null;
  for (const [nombre, mensaje] of Object.entries(campos || {})) {
    const input = contenedor.querySelector(`[name="${nombre}"]`);
    if (input) { mostrarError(input, mensaje); primero ??= input; }
  }
  primero?.focus();
  return !!primero;
}
function limpiarErrores(contenedor) {
  contenedor.querySelectorAll(".field").forEach(c => c.classList.remove("invalid", "valid"));
  contenedor.querySelectorAll(".field-error").forEach(e => (e.textContent = ""));
  contenedor.querySelectorAll("[data-tocado]").forEach(i => delete i.dataset.tocado);
}
// Valida al salir del campo, y mientras escribe si ya se había equivocado
document.addEventListener("focusout", (e) => {
  if (e.target.matches?.(".field [name]") && e.target.value) { e.target.dataset.tocado = "1"; validarCampo(e.target); }
});
document.addEventListener("input", (e) => {
  const t = e.target;
  if (!t.matches?.(".field [name]")) return;
  if (["documento", "telefono"].includes(t.name)) t.value = t.value.replace(/\D/g, "");
  if (t.dataset.tocado) validarCampo(t);
  if (t.name === "contrasenia" && t.form?.confirmar?.dataset.tocado) validarCampo(t.form.confirmar);
});

/* ====== Sesión ====== */
function cerrarModales() {
  document.querySelectorAll(".modal.open").forEach(m => m.classList.remove("open"));
}
function abrirLogin(v) {
  cerrarModales();
  if (!v) return;
  limpiarErrores($("#loginForm")); $("#loginError").textContent = "";
  $("#loginModal").classList.add("open");
  setTimeout(() => $("#email").focus(), 50);
}
async function abrirRegistro() {
  cerrarModales();
  const f = $("#registroForm");
  limpiarErrores(f); $("#registroError").textContent = "";
  $("#registroModal").classList.add("open");
  setTimeout(() => f.primer_nombre.focus(), 50);
  try {
    const centros = await api("/centros");
    f.id_centro.innerHTML = (centros.length > 1 ? `<option value="">Elige…</option>` : "") +
      centros.map(c => `<option value="${c.id}">${esc(c.nombre)} · ${esc(c.ciudad)}</option>`).join("");
  } catch (e) { $("#registroError").textContent = e.message; }
}
function iniciarSesion(r) {
  token = r.token; usuario = r.usuario;
  sessionStorage.setItem("token", token); sessionStorage.setItem("usuario", JSON.stringify(usuario));
  cerrarModales(); pintarUsuario(); toast(`¡Hola, ${usuario.nombre}!`);
  if (usuario.rol !== "empleado") { carrito = {}; pintarCarrito(); return abrirPanel(); }
  if (pendienteCheckout) { pendienteCheckout = false; confirmarPedido(); }
}
function pintarUsuario() {
  $("#btnUser").textContent = usuario ? `👤 ${usuario.nombre} · Salir` : "Iniciar sesión";
  $("#btnCart").hidden = !esEmpleado();
  $("#btnPedidos").hidden = !usuario;
  $("#btnPedidos").textContent = !usuario ? "" : usuario.rol === "empleado" ? "📋 Mis pedidos"
    : usuario.rol === "domiciliario" ? "🛵 Mis entregas" : "🍳 Panel";
}
function cerrarSesion(avisar = true) {
  token = null; usuario = null; cupon = null;
  sessionStorage.removeItem("token"); sessionStorage.removeItem("usuario");
  pintarUsuario(); pintarCarrito(); mostrarVista("#viewMenu");
  if (avisar) toast("Sesión cerrada");
}
$("#loginForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  const f = e.target;
  $("#loginError").textContent = "";
  if (!validarTodo(f)) return;
  const boton = f.querySelector("[type=submit]");
  boton.disabled = true; boton.textContent = "Entrando…";
  try {
    const r = await api("/login", { method: "POST",
      body: JSON.stringify({ correo: f.correo.value.trim(), contrasenia: f.contrasenia.value }) });
    f.contrasenia.value = ""; limpiarErrores(f);
    iniciarSesion(r);
  } catch (err) {
    if (!erroresDelServidor(f, err.campos)) $("#loginError").textContent = err.message;
  } finally { boton.disabled = false; boton.textContent = "Entrar"; }
});
$("#registroForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  const f = e.target;
  $("#registroError").textContent = "";
  if (!validarTodo(f)) { $("#registroError").textContent = "Revisa los campos marcados en rojo"; return; }
  const datos = Object.fromEntries(new FormData(f));
  delete datos.confirmar;
  datos.id_centro = Number(datos.id_centro);
  const boton = f.querySelector("[type=submit]");
  boton.disabled = true; boton.textContent = "Creando cuenta…";
  try {
    const r = await api("/registro", { method: "POST", body: JSON.stringify(datos) });
    f.reset(); limpiarErrores(f);
    iniciarSesion(r);
    toast(`¡Bienvenido, ${r.usuario.nombre}! Tu cuenta quedó creada`);
  } catch (err) {
    erroresDelServidor(f, err.campos);
    $("#registroError").textContent = err.message;
  } finally { boton.disabled = false; boton.textContent = "Crear cuenta"; }
});

/* ====== Pedido y seguimiento ====== */
let pendienteCheckout = false;
async function confirmarPedido() {
  if (!Object.keys(carrito).length) return toast("Agrega productos primero");
  if (!usuario) { pendienteCheckout = true; abrirLogin(true); return; }   // exige login
  $("#address").dataset.tocado = "1";
  if (!validarCampo($("#address"))) { $("#address").focus(); return toast("Indica el punto de entrega"); }
  const dir = $("#address").value.trim();
  const boton = $("#checkout");
  boton.disabled = true; boton.textContent = "Enviando…";
  try {
    const pedido = await api("/pedidos", { method: "POST", body: JSON.stringify({
      punto_entrega: dir, cupon: cupon?.codigo,
      items: Object.entries(carrito).map(([id, cantidad]) => ({ id: +id, cantidad })) }) });
    carrito = {}; cupon = null; $("#couponInput").value = ""; $("#couponMsg").textContent = "";
    pintarCarrito(); abrirCarrito(false);
    seguirPedido(pedido);
  } catch (e) {
    if (!erroresDelServidor($("#cart"), e.campos)) toast(e.message);
    if (/agotado/i.test(e.message)) cargarMenu();
  } finally { boton.disabled = false; boton.textContent = "Confirmar pedido"; }
}

const FLUJO = ["pendiente", "preparando", "en_camino", "entregado"];
const TITULOS = {
  pendiente: ["🧾", "¡Recibimos tu pedido!"], preparando: ["👩‍🍳", "¡Tu producto está en preparación!"],
  en_camino: ["🚚", "¡Tu pedido va en camino!"], entregado: ["🎉", "¡Pedido entregado!"], cancelado: ["❌", "Pedido cancelado"],
};
function pintarSeguimiento(p) {
  const n = FLUJO.indexOf(p.estado);
  document.querySelectorAll("#steps li").forEach((li, i) => {
    li.className = p.estado === "cancelado" ? "" : i < n || p.estado === "entregado" ? "done" : i === n ? "now" : "";
  });
  $("#statusIcon").textContent = TITULOS[p.estado][0];
  $("#statusTitle").textContent = TITULOS[p.estado][1];
  $("#statusInfo").textContent = `Pedido #${p.id} · ${p.restaurante} · Entrega en: ${p.punto_entrega}`;
  $("#statusExtra").textContent =
    p.estado === "entregado" ? `Llegó en ${p.tiempo_real ?? "–"} min${p.domiciliario ? " · Lo entregó " + p.domiciliario : ""}`
    : p.estado === "cancelado" ? "Este pedido fue cancelado."
    : `Tiempo estimado: ${p.tiempo_estimado} min${p.domiciliario ? " · Domiciliario: " + p.domiciliario : ""}`;
  $("#statusSummary").innerHTML = p.items.map(i => `<div>${i.cantidad} × ${esc(i.nombre)} <span class="muted">${money(i.subtotal)}</span></div>`).join("") +
    (p.descuento ? `<div>Descuento${p.cupon ? " (" + esc(p.cupon) + ")" : ""}: -${money(p.descuento)}</div>` : "") +
    `<div><b>Total: ${money(p.total)}</b></div>`;
  $("#btnCancel").hidden = p.estado !== "pendiente";
  $("#btnCancel").dataset.id = p.id;
}
function seguirPedido(p) {
  mostrarVista("#viewStatus");
  pintarSeguimiento(p);
  clearInterval(window.timer);
  if (["entregado", "cancelado"].includes(p.estado)) return;
  // Consulta el estado real del pedido en el servidor cada 4 s
  window.timer = setInterval(async () => {
    try {
      const nuevo = await api(`/pedidos/${p.id}`);
      if (nuevo.estado !== p.estado && nuevo.estado === "entregado") toast("¡Tu pedido fue entregado! 🎉");
      p = nuevo; pintarSeguimiento(p);
      if (["entregado", "cancelado"].includes(p.estado)) clearInterval(window.timer);
    } catch { /* reintenta en el siguiente ciclo */ }
  }, 4000);
}
async function cambiarEstado(id, estado) {
  return api(`/pedidos/${id}/estado`, { method: "PATCH", body: JSON.stringify({ estado }) });
}

/* ====== Paneles ====== */
let pestana = "pedidos";
let ultimoPanel = "";
function abrirPanel() {
  mostrarVista("#viewPanel");
  const rol = usuario.rol;
  $("#panelTitle").textContent = rol === "empleado" ? "Mis pedidos" : rol === "domiciliario" ? "Mis entregas" : "Panel del restaurante";
  $("#panelSub").textContent = rol === "empleado" ? "Toca un pedido para ver su seguimiento."
    : rol === "domiciliario" ? "Pedidos que te asignaron. Al entregar, sube la foto de evidencia."
    : "Prepara, asigna domiciliario y despacha los pedidos.";
  const tabs = rol === "restaurante" || rol === "admin"
    ? [["pedidos", "Pedidos activos"], ["historial", "Historial"], ["productos", "Productos"]]
    : rol === "domiciliario" ? [["pedidos", "Por entregar"], ["historial", "Entregados"]] : [];
  if (!tabs.some(t => t[0] === pestana)) pestana = "pedidos";
  $("#panelTabs").innerHTML = tabs.map(([k, t]) => `<button class="chip ${k === pestana ? "on" : ""}" data-tab="${k}">${t}</button>`).join("");
  ultimoPanel = "";
  cargarPanel();
  clearInterval(window.timerPanel);
  window.timerPanel = setInterval(() => cargarPanel(true), 5000);
}
async function cargarPanel(silencioso = false) {
  // No refresca mientras el usuario está eligiendo un domiciliario o una foto
  if (silencioso && document.activeElement?.closest("#panelBody select, #panelBody input")) return;
  if (!silencioso) $("#panelBody").innerHTML = `<p class="muted">Cargando…</p>`;
  try {
    let html;
    if (pestana === "productos") {
      if (silencioso) return;
      html = pintarProductosPanel(await api("/mis-productos"));
    } else {
      const activos = pestana === "pedidos" && usuario.rol !== "empleado";
      let lista = await api("/pedidos" + (activos ? "?activos=1" : ""));
      if (pestana === "historial") lista = lista.filter(p => ["entregado", "cancelado"].includes(p.estado));
      const repartidores = activos && usuario.rol !== "domiciliario" && lista.some(p => !p.id_domiciliario && p.estado !== "cancelado")
        ? await api("/domiciliarios/disponibles") : [];
      html = lista.length ? lista.map(p => tarjetaPedido(p, repartidores)).join("")
        : `<p class="muted vacio">${pestana === "historial" ? "Todavía no hay pedidos terminados." : "No hay pedidos por ahora. 🎉"}</p>`;
    }
    if (html === ultimoPanel) return;
    ultimoPanel = html; $("#panelBody").innerHTML = html;
  } catch (e) {
    if (!silencioso) $("#panelBody").innerHTML = `<p class="error">${esc(e.message)}</p>`;
  }
}
function tarjetaPedido(p, repartidores) {
  const rol = usuario.rol, gestiona = rol === "restaurante" || rol === "admin";
  let acciones = "";
  if (gestiona && p.estado === "pendiente")
    acciones += `<button class="btn" data-estado="preparando" data-id="${p.id}">👩‍🍳 Empezar a preparar</button>`;
  if (gestiona && ["pendiente", "preparando"].includes(p.estado) && !p.id_domiciliario)
    acciones += repartidores.length
      ? `<select data-dom-select="${p.id}">${repartidores.map(d => `<option value="${d.id}">${esc(d.nombre)} (${esc(d.tipo_vehiculo.replace("_", " "))})</option>`).join("")}</select>
         <button class="btn ghost" data-asignar="${p.id}">Asignar</button>`
      : `<span class="muted small">No hay domiciliarios disponibles</span>`;
  if (gestiona && p.estado === "preparando" && p.id_domiciliario)
    acciones += `<button class="btn" data-estado="en_camino" data-id="${p.id}">🚚 Despachar</button>`;
  if (gestiona && ["pendiente", "preparando"].includes(p.estado))
    acciones += `<button class="btn ghost danger" data-estado="cancelado" data-id="${p.id}">Cancelar</button>`;
  if (rol === "domiciliario" && p.estado === "en_camino")
    acciones += `<label class="file-btn">📷 Foto de entrega<input type="file" accept="image/*" capture="environment" data-evidencia="${p.id}"></label>
      <button class="btn" data-entregar="${p.id}">✅ Marcar entregado</button>`;

  return `<article class="order ${rol === "empleado" ? "clickable" : ""}" ${rol === "empleado" ? `data-ver="${p.id}"` : ""}>
    <header><b>Pedido #${p.id}</b><span class="estado ${p.estado}">${ETIQUETA[p.estado]}</span></header>
    <div class="order-meta">
      ${rol === "empleado" ? `<span>🍽️ ${esc(p.restaurante)}</span>` : `<span>👤 ${esc(p.empleado)} · ${esc(p.telefono_empleado)}</span>`}
      <span>📍 ${esc(p.punto_entrega)}</span>
      <span>🕒 ${p.fecha.slice(0, 10)} ${hora(p.fecha)}${p.tiempo_real != null ? ` · llegó en ${p.tiempo_real} min` : ` · estimado ${p.tiempo_estimado} min`}</span>
      ${p.domiciliario ? `<span>🛵 ${esc(p.domiciliario)}</span>` : ""}
    </div>
    <ul class="order-items">${p.items.map(i => `<li>${i.cantidad} × ${esc(i.nombre)}</li>`).join("")}</ul>
    <div class="order-foot"><b>${money(p.total)}</b>${p.evidencia ? ` <a href="${esc(foto(p.evidencia))}" target="_blank" rel="noopener">Ver foto de entrega</a>` : ""}</div>
    ${acciones ? `<div class="order-actions">${acciones}</div>` : ""}
  </article>`;
}
function pintarProductosPanel(lista) {
  if (!lista.length) return `<p class="muted vacio">Tu restaurante no tiene productos.</p>`;
  return lista.map(p => {
    const r = restaurantes.find(x => x.id === p.r);
    return `<article class="order prod-row">
      <div class="prod-thumb">${img(foto(p.foto), p.nombre, emojiDe(r))}</div>
      <div class="prod-info"><b>${esc(p.nombre)}</b><span class="muted small">${money(p.precio)}</span></div>
      <div class="order-actions">
        <button class="btn ${p.disponible ? "ghost" : ""}" data-toggle="${p.id}" data-disp="${p.disponible ? 0 : 1}">${p.disponible ? "Marcar agotado" : "Marcar disponible"}</button>
        <label class="file-btn">📷 Cambiar foto<input type="file" accept="image/*" data-foto="${p.id}"></label>
      </div></article>`;
  }).join("");
}
async function accionPanel(fn, okMsg) {
  try { await fn(); if (okMsg) toast(okMsg); }
  catch (e) { toast(e.message); }
  ultimoPanel = ""; cargarPanel(true);
}

/* ====== Eventos ====== */
document.addEventListener("click", async (e) => {
  const t = e.target.closest("button, [data-ver]") || e.target;
  const d = t.dataset || {};
  if (d.r !== undefined && t.classList.contains("chip")) { filtro = +d.r; pintarFiltros(); pintarMenu(); }
  if (d.add) agregar(+d.add);
  if (d.inc) { carrito[d.inc]++; pintarCarrito(); }
  if (d.dec) { if (--carrito[d.dec] <= 0) delete carrito[d.dec]; pintarCarrito(); }
  if (d.cupon) aplicarCupon(d.cupon);
  if (d.tab) { pestana = d.tab; abrirPanel(); }
  if (d.ver) { try { seguirPedido(await api(`/pedidos/${d.ver}`)); } catch (err) { toast(err.message); } }
  if (d.estado && d.id) {
    if (d.estado === "cancelado" && !confirmarAccion(t)) return;
    accionPanel(() => cambiarEstado(d.id, d.estado), `Pedido #${d.id}: ${ETIQUETA[d.estado].toLowerCase()}`);
  }
  if (d.asignar) {
    const id_domiciliario = +$(`[data-dom-select="${d.asignar}"]`).value;
    accionPanel(() => api(`/pedidos/${d.asignar}/domiciliario`, { method: "PATCH", body: JSON.stringify({ id_domiciliario }) }), "Domiciliario asignado");
  }
  if (d.entregar) {
    const archivo = $(`[data-evidencia="${d.entregar}"]`).files[0];
    if (!archivo && !confirmarAccion(t, "¿Entregar sin foto?")) return;
    const fd = new FormData(); if (archivo) fd.append("archivo", archivo);
    accionPanel(() => api(`/pedidos/${d.entregar}/entregar`, { method: "POST", body: fd }), "¡Pedido entregado!");
  }
  if (d.toggle) accionPanel(() => api(`/productos/${d.toggle}`, { method: "PATCH", body: JSON.stringify({ disponible: d.disp === "1" }) }))
    .then(() => { ultimoPanel = ""; cargarPanel(); cargarMenu(); });
  if (t.hasAttribute?.("data-close") || t.classList?.contains("modal")) { pendienteCheckout = false; cerrarModales(); }
  if (t.hasAttribute?.("data-ir-registro")) abrirRegistro();
  if (t.hasAttribute?.("data-ir-login")) abrirLogin(true);
});
// Confirmación en dos toques (sin ventanas emergentes del navegador)
function confirmarAccion(boton, texto = "¿Seguro? Toca otra vez") {
  if (boton.dataset.confirmado) return true;
  const original = boton.textContent;
  boton.dataset.confirmado = "1"; boton.textContent = texto;
  setTimeout(() => { delete boton.dataset.confirmado; boton.textContent = original; }, 3000);
  return false;
}
document.addEventListener("change", (e) => {
  const t = e.target;
  if (t.dataset.foto && t.files[0]) {
    const fd = new FormData(); fd.append("archivo", t.files[0]);
    accionPanel(() => api(`/productos/${t.dataset.foto}/foto`, { method: "POST", body: fd }), "Foto actualizada")
      .then(() => { ultimoPanel = ""; cargarPanel(); cargarMenu(); });
  }
  if (t.dataset.evidencia && t.files[0]) t.closest("label").firstChild.textContent = "📷 " + t.files[0].name.slice(0, 18);
});
$("#btnCart").onclick = () => abrirCarrito(true);
$("#closeCart").onclick = $("#overlay").onclick = () => abrirCarrito(false);
$("#btnUser").onclick = () => usuario ? cerrarSesion() : abrirLogin(true);
$("#btnPedidos").onclick = abrirPanel;
$("#brand").onclick = () => usuario && !esEmpleado() ? abrirPanel() : mostrarVista("#viewMenu");
$("#checkout").onclick = confirmarPedido;
$("#btnBack").onclick = () => { mostrarVista("#viewMenu"); cargarMenu(); };
$("#btnCancel").onclick = async (e) => {
  if (!confirmarAccion(e.target)) return;
  try { seguirPedido(await cambiarEstado(e.target.dataset.id, "cancelado")); toast("Pedido cancelado"); }
  catch (err) { toast(err.message); }
};
$("#applyCoupon").onclick = () => aplicarCupon($("#couponInput").value);
document.addEventListener("keydown", (e) => { if (e.key === "Escape") { cerrarModales(); abrirCarrito(false); } });
$("#couponInput").onkeydown = (e) => { if (e.key === "Enter") aplicarCupon(e.target.value); };
let tt; function toast(m) { const el = $("#toast"); el.textContent = m; el.classList.add("on"); clearTimeout(tt); tt = setTimeout(() => el.classList.remove("on"), 2600); }

pintarCarrito(); pintarUsuario(); cargarMenu();
if (usuario && !esEmpleado()) abrirPanel();
