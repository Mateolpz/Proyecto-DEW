/* ====== Datos demo (en producción vienen de la BD vía conexion.sql / API) ====== */
const IMG = (id) => `https://images.unsplash.com/${id}?w=600&q=70`;
const restaurantes = [
  { id: 1, nombre: "Burger House",  emoji: "🍔", foto: IMG("photo-1568901346375-23c9450c58cd") },
  { id: 2, nombre: "Pizza Piazza",  emoji: "🍕", foto: IMG("photo-1513104890138-7c749659a591") },
  { id: 3, nombre: "Sabor Criollo", emoji: "🍛", foto: IMG("photo-1512058564366-18510be2db19") },
];
const productos = [
  { id: 1, r: 1, nombre: "Hamburguesa clásica", desc: "Carne 150 g, queso, lechuga y tomate.", precio: 18000, disp: 1, emoji: "🍔", foto: IMG("photo-1568901346375-23c9450c58cd") },
  { id: 2, r: 1, nombre: "Papas criollas",      desc: "Porción grande con salsas de la casa.", precio: 9000,  disp: 1, emoji: "🍟", foto: IMG("photo-1573080496219-bb080dd4f877") },
  { id: 3, r: 2, nombre: "Pizza pepperoni",     desc: "Personal de 6 porciones.",              precio: 22000, disp: 1, emoji: "🍕", foto: IMG("photo-1628840042765-356cda07504e") },
  { id: 4, r: 2, nombre: "Pizza hawaiana",      desc: "Jamón y piña sobre masa artesanal.",    precio: 21000, disp: 0, emoji: "🍍", foto: IMG("photo-1565299624946-b28f40a0ae38") },
  { id: 5, r: 3, nombre: "Bandeja del día",     desc: "Arroz, fríjoles, carne, plátano y huevo.", precio: 20000, disp: 1, emoji: "🍛", foto: IMG("photo-1512058564366-18510be2db19") },
  { id: 6, r: 3, nombre: "Sopa de pollo",       desc: "Con papa, yuca y arroz aparte.",        precio: 14000, disp: 1, emoji: "🍲", foto: IMG("photo-1547592166-23ac45744acd") },
];
const clientes = [{ id: 1, nombre: "Ana", correo: "ana@centro.com", contrasenia: "1234" }];
const cupones  = [
  { id: 1, codigo: "EMPLEADO10", descuento: 0.10, condiciones: "10% de descuento" },
  { id: 2, codigo: "PROMO5000",  descuento: 5000, condiciones: "$5.000 de descuento" },
];

/* ====== Estado ====== */
const $ = (s) => document.querySelector(s);
const money = (n) => "$" + Math.round(n).toLocaleString("es-CO");
let filtro = 0;
let carrito = {};           // {idProducto: cantidad}
let cupon = null;
let cliente = JSON.parse(sessionStorage.getItem("cliente") || "null");

/* ====== Menú ====== */
function pintarFiltros() {
  const chips = [{ id: 0, nombre: "Todos" }, ...restaurantes];
  $("#filters").innerHTML = chips.map(c =>
    `<button class="chip ${c.id === filtro ? "on" : ""}" data-r="${c.id}">${c.nombre}</button>`).join("");
}
function pintarMenu() {
  const lista = productos.filter(p => !filtro || p.r === filtro);
  $("#grid").innerHTML = lista.map(p => {
    const r = restaurantes.find(x => x.id === p.r);
    return `<article class="card ${p.disp ? "" : "off"}">
      <div class="photo"><img src="${p.foto}" alt="${p.nombre}" loading="lazy" onerror="this.replaceWith('${p.emoji}')"></div>
      <div class="rest-logo" title="${r.nombre}"><img src="${r.foto}" alt="${r.nombre}" onerror="this.replaceWith('${r.emoji}')"></div>
      <div class="body">
        <span class="rest-name">${r.nombre}</span>
        <h3>${p.nombre}</h3>
        <p>${p.desc}</p>
        <div class="foot"><span class="price">${money(p.precio)}</span>
          <button class="btn" data-add="${p.id}">${p.disp ? "Agregar" : "Agotado"}</button></div>
      </div></article>`;
  }).join("");
}

/* ====== Carrito ====== */
function restauranteDelCarrito() {
  const ids = Object.keys(carrito);
  return ids.length ? productos.find(p => p.id == ids[0]).r : null;
}
function agregar(id) {
  const p = productos.find(x => x.id === id);
  const rc = restauranteDelCarrito();
  // Regla de negocio 1: un pedido = un solo restaurante
  if (rc && rc !== p.r) return toast("Tu pedido solo puede ser de un restaurante. Vacía el carrito para cambiar.");
  carrito[id] = (carrito[id] || 0) + 1;
  pintarCarrito(); toast(`${p.nombre} agregado`);
}
function totales() {
  const sub = Object.entries(carrito).reduce((s, [id, q]) => s + productos.find(p => p.id == id).precio * q, 0);
  let desc = 0;
  if (cupon) desc = cupon.descuento < 1 ? sub * cupon.descuento : Math.min(cupon.descuento, sub);
  return { sub, desc, total: sub - desc };
}
function pintarCarrito() {
  const ids = Object.keys(carrito);
  $("#cartCount").textContent = ids.reduce((s, i) => s + carrito[i], 0);
  $("#cartItems").innerHTML = ids.length ? ids.map(id => {
    const p = productos.find(x => x.id == id);
    return `<div class="item"><div><b>${p.nombre}</b><br><small>${money(p.precio)}</small></div>
      <div class="qty"><button data-dec="${id}">−</button><b>${carrito[id]}</b><button data-inc="${id}">+</button></div></div>`;
  }).join("") : `<p class="muted">Tu carrito está vacío.</p>`;
  const t = totales();
  $("#tSub").textContent = money(t.sub); $("#tDisc").textContent = "-" + money(t.desc); $("#tTotal").textContent = money(t.total);
}
const abrirCarrito = (v) => { $("#cart").classList.toggle("open", v); $("#overlay").classList.toggle("on", v); };

/* ====== Login (ventana emergente) ====== */
const abrirLogin = (v) => $("#loginModal").classList.toggle("open", v);
function pintarUsuario() {
  $("#btnUser").textContent = cliente ? `👤 ${cliente.nombre} · Salir` : "Iniciar sesión";
}
$("#loginForm").addEventListener("submit", (e) => {
  e.preventDefault();
  // En producción: SELECT ... FROM clientes WHERE correo=? AND contrasenia=? (ver conexion.sql)
  const u = clientes.find(c => c.correo === $("#email").value.trim() && c.contrasenia === $("#password").value);
  if (!u) { $("#loginError").textContent = "Correo o contraseña incorrectos."; return; }
  cliente = u; sessionStorage.setItem("cliente", JSON.stringify(u));
  $("#loginError").textContent = ""; abrirLogin(false); pintarUsuario(); toast(`¡Hola, ${u.nombre}!`);
  if (pendienteCheckout) { pendienteCheckout = false; confirmarPedido(); }
});

/* ====== Pedido y landing "en preparación" ====== */
let pendienteCheckout = false;
function confirmarPedido() {
  if (!Object.keys(carrito).length) return toast("Agrega productos primero");
  if (!cliente) { pendienteCheckout = true; abrirLogin(true); return; }   // exige login
  const dir = $("#address").value.trim();
  if (!dir) return toast("Indica el punto de entrega");
  const t = totales();
  const pedido = { id: Math.floor(Math.random() * 9000 + 1000), direccion: dir, ...t,
    items: Object.entries(carrito).map(([id, q]) => ({ ...productos.find(p => p.id == id), q })) };
  mostrarEstado(pedido);
  carrito = {}; cupon = null; $("#couponInput").value = ""; $("#couponMsg").textContent = "";
  pintarCarrito(); abrirCarrito(false);
}
function mostrarEstado(p) {
  $("#viewMenu").classList.remove("active"); $("#viewStatus").classList.add("active");
  window.scrollTo(0, 0);
  $("#statusInfo").textContent = `Pedido #${p.id} · Entrega en: ${p.direccion}`;
  $("#statusSummary").innerHTML = p.items.map(i => `<div>${i.q} × ${i.nombre}</div>`).join("") +
    `<div><b>Total: ${money(p.total)}</b></div>`;
  // Flujo: pendiente → preparando → en camino → entregado (simulado)
  const flujo = ["pendiente", "preparando", "en camino", "entregado"];
  let n = 1;
  const marcar = () => document.querySelectorAll("#steps li").forEach((li, i) => {
    li.className = i < n ? "done" : i === n ? "now" : "";
  });
  marcar(); clearInterval(window.timer);
  window.timer = setInterval(() => { if (n < flujo.length - 1) { n++; marcar(); } else { n = 4; marcar(); clearInterval(window.timer); } }, 8000);
}

/* ====== Eventos ====== */
document.addEventListener("click", (e) => {
  const t = e.target;
  if (t.dataset.r !== undefined && t.classList.contains("chip")) { filtro = +t.dataset.r; pintarFiltros(); pintarMenu(); }
  if (t.dataset.add) agregar(+t.dataset.add);
  if (t.dataset.inc) { carrito[t.dataset.inc]++; pintarCarrito(); }
  if (t.dataset.dec) { if (--carrito[t.dataset.dec] <= 0) delete carrito[t.dataset.dec]; pintarCarrito(); }
  if (t.hasAttribute("data-close") || t === $("#loginModal")) abrirLogin(false);
});
$("#btnCart").onclick = () => abrirCarrito(true);
$("#closeCart").onclick = $("#overlay").onclick = () => abrirCarrito(false);
$("#btnUser").onclick = () => {
  if (cliente) { cliente = null; sessionStorage.removeItem("cliente"); pintarUsuario(); toast("Sesión cerrada"); }
  else abrirLogin(true);
};
$("#checkout").onclick = confirmarPedido;
$("#btnBack").onclick = () => { clearInterval(window.timer); $("#viewStatus").classList.remove("active"); $("#viewMenu").classList.add("active"); };
$("#applyCoupon").onclick = () => {
  const c = cupones.find(x => x.codigo === $("#couponInput").value.trim().toUpperCase());
  cupon = c || null;
  $("#couponMsg").textContent = c ? `✅ ${c.condiciones}` : "Cupón no válido";
  pintarCarrito();
};
let tt; function toast(m) { const el = $("#toast"); el.textContent = m; el.classList.add("on"); clearTimeout(tt); tt = setTimeout(() => el.classList.remove("on"), 2400); }

pintarFiltros(); pintarMenu(); pintarCarrito(); pintarUsuario();