-- =====================================================================
-- FoodCourt Express - Datos de demostración
-- Ejecutar DESPUÉS de schema.sql
--
-- Contiene: 1 centro comercial, 23 usuarios (10 empleados, 6 restaurantes,
-- 6 domiciliarios, 1 admin), 6 restaurantes, 28 productos, 6 cupones y
-- 28 pedidos de las últimas dos semanas en todos los estados.
-- Las fechas se calculan desde hoy, así los datos siempre se ven recientes.
--
-- Todos los usuarios entran con la clave 1234: al arrancar, el backend
-- reemplaza 'HASH_PENDIENTE' por un hash bcrypt.
-- =====================================================================
SET NAMES utf8mb4;   -- tildes y ñ correctas aunque se ejecute desde la consola
USE foodcourt;

INSERT INTO centros_comerciales (nombre, direccion, ciudad) VALUES
  ('Centro Comercial Unicentro', 'Carrera 100 # 5-169', 'Cali');

-- ---------------------------------------------------------- usuarios
INSERT INTO usuarios (id_usuario, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
                      documento, telefono, correo, contrasenia_hash, rol) VALUES
  (1, 'Ana', 'María', 'Gómez', 'Ruiz', '1144000001', '3001000001', 'ana@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (2, 'Julián', NULL, 'Torres', NULL, '1144000002', '3001000002', 'julian@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (3, 'Pedro', NULL, 'Ramírez', 'López', '1144000003', '3001000003', 'burger@foodcourt.co', 'HASH_PENDIENTE', 'restaurante'),
  (4, 'Lucía', NULL, 'Moreno', NULL, '1144000004', '3001000004', 'pizza@foodcourt.co', 'HASH_PENDIENTE', 'restaurante'),
  (5, 'Rosa', 'Elena', 'Valencia', NULL, '1144000005', '3001000005', 'criollo@foodcourt.co', 'HASH_PENDIENTE', 'restaurante'),
  (6, 'Andrés', NULL, 'Castillo', 'Mejía', '1144000006', '3001000006', 'andres@foodcourt.co', 'HASH_PENDIENTE', 'domiciliario'),
  (7, 'Camila', NULL, 'Rojas', NULL, '1144000007', '3001000007', 'camila@foodcourt.co', 'HASH_PENDIENTE', 'domiciliario'),
  (8, 'Admin', NULL, 'Sistema', NULL, '1144000008', '3001000008', 'admin@foodcourt.co', 'HASH_PENDIENTE', 'admin'),
  (9, 'Valentina', NULL, 'Ospina', 'Mejía', '1144000009', '3001000009', 'valentina@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (10, 'Santiago', NULL, 'Herrera', NULL, '1144000010', '3001000010', 'santiago@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (11, 'Daniela', 'Andrea', 'Muñoz', NULL, '1144000011', '3001000011', 'daniela@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (12, 'Felipe', NULL, 'Cárdenas', 'Ruiz', '1144000012', '3001000012', 'felipe@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (13, 'Mariana', NULL, 'Castaño', NULL, '1144000013', '3001000013', 'mariana@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (14, 'Sebastián', NULL, 'Arango', 'Díaz', '1144000014', '3001000014', 'sebastian@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (15, 'Laura', 'Sofía', 'Quintero', NULL, '1144000015', '3001000015', 'laura@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (16, 'Juan', 'Pablo', 'Rincón', NULL, '1144000016', '3001000016', 'juanpablo@centro.com', 'HASH_PENDIENTE', 'empleado'),
  (17, 'Tomás', NULL, 'Nakamura', 'Salazar', '1144000017', '3001000017', 'sushi@foodcourt.co', 'HASH_PENDIENTE', 'restaurante'),
  (18, 'Isabel', NULL, 'Sarmiento', NULL, '1144000018', '3001000018', 'postres@foodcourt.co', 'HASH_PENDIENTE', 'restaurante'),
  (19, 'Ricardo', NULL, 'Lozano', 'Pérez', '1144000019', '3001000019', 'cafe@foodcourt.co', 'HASH_PENDIENTE', 'restaurante'),
  (20, 'Jhon', 'Jairo', 'Mosquera', NULL, '1144000020', '3001000020', 'jhon@foodcourt.co', 'HASH_PENDIENTE', 'domiciliario'),
  (21, 'Paola', NULL, 'Ibarra', NULL, '1144000021', '3001000021', 'paola@foodcourt.co', 'HASH_PENDIENTE', 'domiciliario'),
  (22, 'Esteban', NULL, 'Patiño', 'Gil', '1144000022', '3001000022', 'esteban@foodcourt.co', 'HASH_PENDIENTE', 'domiciliario'),
  (23, 'Natalia', NULL, 'Vélez', NULL, '1144000023', '3001000023', 'natalia@foodcourt.co', 'HASH_PENDIENTE', 'domiciliario');

-- Empleados del centro comercial (Juan Pablo aún no está verificado: no puede pedir)
INSERT INTO empleados (id_usuarioFK, id_centroFK, local_trabajo, verificado) VALUES
  (1, 1, 'Falabella, piso 1', TRUE),
  (2, 1, 'Cine Colombia, piso 3', TRUE),
  (9, 1, 'Zara, piso 2', TRUE),
  (10, 1, 'Almacenes Éxito, piso 1', TRUE),
  (11, 1, 'Arturo Calle, piso 2', TRUE),
  (12, 1, 'Banco de Bogotá, piso 1', TRUE),
  (13, 1, 'Studio F, piso 2', TRUE),
  (14, 1, 'Cine Colombia, piso 3', TRUE),
  (15, 1, 'Pepe Ganga, piso 1', TRUE),
  (16, 1, 'Mac Center, piso 2', FALSE);

INSERT INTO domiciliarios (id_usuarioFK, tipo_vehiculo, placa_vehiculo, disponible) VALUES
  (6, 'bicicleta', NULL, TRUE),
  (7, 'patineta', NULL, TRUE),
  (20, 'moto', 'KLM23F', TRUE),
  (21, 'bicicleta', NULL, TRUE),
  (22, 'moto', 'BTR58E', TRUE),
  (23, 'a_pie', NULL, TRUE);

-- ---------------------------------------------------------- restaurantes
INSERT INTO restaurantes (id_restaurante, id_centroFK, id_administradorFK, nombre_restaurante, categoria,
                          local, piso, telefono, hora_apertura, hora_cierre) VALUES
  (1, 1, 3, 'Burger House', 'Hamburguesas', '301', 3, '6023000001', '10:00', '21:00'),
  (2, 1, 4, 'Pizza Piazza', 'Pizzería', '305', 3, '6023000002', '11:00', '22:00'),
  (3, 1, 5, 'Sabor Criollo', 'Comida típica', '310', 3, '6023000003', '08:00', '20:00'),
  (4, 1, 17, 'Sushi Go', 'Sushi', '315', 3, '6023000004', '11:00', '21:30'),
  (5, 1, 18, 'Dulce Antojo', 'Postres', '220', 2, '6023000005', '09:00', '21:00'),
  (6, 1, 19, 'Café Origen', 'Café', '118', 1, '6023000006', '07:00', '20:00');

-- Fotos de productos (solo metadatos; los archivos irían en backend/uploads/productos/).
-- Para que se vean en la demo, súbanlas desde el panel del restaurante.
INSERT INTO archivos (id_archivo, nombre_original, nombre_almacenado, tipo_mime, peso_bytes, ruta_url, categoria, id_autorFK) VALUES
  (1, 'hamburguesa clasica.jpg', 'a1f0c3d2-0001-4b7e-9c1a-000000000001.jpg', 'image/jpeg', 245760, 'uploads/productos/a1f0c3d2-0001-4b7e-9c1a-000000000001.jpg', 'foto_producto', 3),
  (2, 'papas.jpg',               'a1f0c3d2-0002-4b7e-9c1a-000000000002.jpg', 'image/jpeg', 198400, 'uploads/productos/a1f0c3d2-0002-4b7e-9c1a-000000000002.jpg', 'foto_producto', 3),
  (3, 'pepperoni.jpg',           'a1f0c3d2-0003-4b7e-9c1a-000000000003.jpg', 'image/jpeg', 301000, 'uploads/productos/a1f0c3d2-0003-4b7e-9c1a-000000000003.jpg', 'foto_producto', 4);

-- ---------------------------------------------------------- productos
INSERT INTO productos (id_producto, id_restauranteFK, nombre_producto, descripcion, precio, disponible, id_fotoFK) VALUES
  (1, 1, 'Hamburguesa clásica', 'Carne 150 g, queso, lechuga y tomate.', 18000, TRUE, 1),
  (2, 1, 'Papas criollas', 'Porción grande con salsas de la casa.', 9000, TRUE, 2),
  (3, 2, 'Pizza pepperoni', 'Personal de 6 porciones.', 22000, TRUE, 3),
  (4, 2, 'Pizza hawaiana', 'Jamón y piña sobre masa artesanal.', 21000, TRUE, NULL),
  (5, 3, 'Bandeja del día', 'Arroz, fríjoles, carne, plátano y huevo.', 20000, TRUE, NULL),
  (6, 3, 'Sopa de pollo', 'Con papa, yuca y arroz aparte.', 14000, TRUE, NULL),
  (7, 1, 'Hamburguesa doble', 'Dos carnes de 150 g, doble queso y tocineta.', 26000, TRUE, NULL),
  (8, 1, 'Hamburguesa de pollo crispy', 'Pechuga apanada, queso y salsa de miel mostaza.', 21000, TRUE, NULL),
  (9, 1, 'Limonada de coco', 'Vaso de 16 oz.', 8000, TRUE, NULL),
  (10, 2, 'Pizza margarita', 'Tomate, mozzarella y albahaca fresca.', 19000, TRUE, NULL),
  (11, 2, 'Lasaña boloñesa', 'Porción individual con pan de ajo.', 24000, TRUE, NULL),
  (12, 2, 'Gaseosa 400 ml', 'Coca-Cola, Sprite o Quatro.', 4500, TRUE, NULL),
  (13, 3, 'Arroz con pollo', 'Con papas a la francesa y ensalada.', 18000, TRUE, NULL),
  (14, 3, 'Sancocho de gallina', 'Con arroz, aguacate y plátano maduro.', 22000, TRUE, NULL),
  (15, 3, 'Jugo natural', 'Mango, mora, lulo o maracuyá. En agua o en leche.', 6000, TRUE, NULL),
  (16, 4, 'Roll California', 'Cangrejo, aguacate y pepino. 10 piezas.', 24000, TRUE, NULL),
  (17, 4, 'Roll acevichado', 'Langostinos y salsa acevichada. 10 piezas.', 28000, TRUE, NULL),
  (18, 4, 'Yakimeshi', 'Arroz salteado con pollo y verduras.', 22000, TRUE, NULL),
  (19, 4, 'Gyozas x6', 'Empanaditas de cerdo con salsa ponzu.', 15000, TRUE, NULL),
  (20, 5, 'Cheesecake de maracuyá', 'Porción individual.', 12000, TRUE, NULL),
  (21, 5, 'Brownie con helado', 'Brownie tibio con helado de vainilla.', 13000, TRUE, NULL),
  (22, 5, 'Torta de chocolate', 'Porción con ganache de chocolate.', 11000, TRUE, NULL),
  (23, 5, 'Postre de natas', 'Receta tradicional vallecaucana.', 9000, TRUE, NULL),
  (24, 6, 'Café americano', 'Café de origen Huila, 12 oz.', 5000, TRUE, NULL),
  (25, 6, 'Capuchino', '12 oz, con canela o cacao.', 7500, TRUE, NULL),
  (26, 6, 'Pandebonos x3', 'Recién horneados.', 6000, TRUE, NULL),
  (27, 6, 'Sándwich de jamón y queso', 'Pan artesanal tostado.', 14000, TRUE, NULL),
  (28, 6, 'Chai latte', 'Té especiado con leche espumada.', 9000, TRUE, NULL);

-- ---------------------------------------------------------- cupones
INSERT INTO cupones (id_cupon, codigo, tipo, valor, fecha_inicio, fecha_fin, usos_maximos, id_restauranteFK, condiciones) VALUES
  (1, 'EMPLEADO10', 'porcentaje', 10, CURDATE() - INTERVAL 30 DAY, CURDATE() + INTERVAL 90 DAY, 100, NULL, '10 % de descuento en cualquier restaurante'),
  (2, 'PROMO5000', 'valor_fijo', 5000, CURDATE() - INTERVAL 30 DAY, CURDATE() + INTERVAL 90 DAY, 50, 2, '$5.000 de descuento en Pizza Piazza'),
  (3, 'VENCIDO20', 'porcentaje', 20, CURDATE() - INTERVAL 60 DAY, CURDATE() - INTERVAL 1 DAY, 100, NULL, 'Cupón vencido, para pruebas'),
  (4, 'SUSHI15', 'porcentaje', 15, CURDATE() - INTERVAL 20 DAY, CURDATE() + INTERVAL 40 DAY, 30, 4, '15 % de descuento en Sushi Go'),
  (5, 'BIENVENIDA', 'porcentaje', 20, CURDATE() - INTERVAL 30 DAY, CURDATE() + INTERVAL 120 DAY, 200, NULL, '20 % en tu primer pedido'),
  (6, 'CAFE2000', 'valor_fijo', 2000, CURDATE() - INTERVAL 15 DAY, CURDATE() + INTERVAL 60 DAY, 100, 6, '$2.000 de descuento en Café Origen');

-- Cupones asignados a cada empleado (Ana conserva EMPLEADO10 y PROMO5000 sin usar para la demo)
INSERT INTO empleado_cupon (id_empleadoFK, id_cuponFK) VALUES
  (1, 1),
  (1, 2),
  (1, 3),
  (1, 6),
  (2, 1),
  (2, 5),
  (9, 1),
  (9, 5),
  (10, 1),
  (10, 4),
  (11, 5),
  (11, 6),
  (12, 1),
  (13, 4),
  (13, 5),
  (14, 1),
  (15, 5),
  (16, 5);

-- ---------------------------------------------------------- pedidos
-- Cada pedido se crea y luego avanza por sus estados con UPDATE, igual que en la app.
-- Los triggers validan cupones, estados y domiciliarios, y llenan el historial solos.

-- Pedido 1: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (1, 2, 1, 1, CURDATE() - INTERVAL 13 DAY + INTERVAL '12:40' HOUR_MINUTE, 'Cine Colombia, piso 3', 45000, 4500, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (1, 1, 2, 18000), (1, 2, 1, 9000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 1;
UPDATE pedidos SET id_domiciliarioFK = 6 WHERE id_pedido = 1;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 1;
INSERT INTO archivos (id_archivo, nombre_original, nombre_almacenado, tipo_mime, peso_bytes, ruta_url, categoria, id_autorFK) VALUES
  (4, 'IMG_2041.jpg', 'e7b2d9f1-0004-4c2a-8d3e-000000000004.jpg', 'image/jpeg', 512000, 'uploads/entregas/e7b2d9f1-0004-4c2a-8d3e-000000000004.jpg', 'evidencia_entrega', 6);
UPDATE pedidos SET estado = 'entregado', tiempo_real = 22, id_evidenciaFK = 4 WHERE id_pedido = 1;

-- Pedido 2: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (2, 9, 2, 5, CURDATE() - INTERVAL 13 DAY + INTERVAL '13:05' HOUR_MINUTE, 'Zara, piso 2', 26500, 5300, 30);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (2, 3, 1, 22000), (2, 12, 1, 4500);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 2;
UPDATE pedidos SET id_domiciliarioFK = 7 WHERE id_pedido = 2;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 2;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 27 WHERE id_pedido = 2;

-- Pedido 3: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (3, 10, 3, NULL, CURDATE() - INTERVAL 12 DAY + INTERVAL '12:15' HOUR_MINUTE, 'Almacenes Éxito, piso 1', 26000, 0, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (3, 5, 1, 20000), (3, 15, 1, 6000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 3;
UPDATE pedidos SET id_domiciliarioFK = 20 WHERE id_pedido = 3;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 3;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 19 WHERE id_pedido = 3;

-- Pedido 4: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (4, 1, 6, 6, CURDATE() - INTERVAL 12 DAY + INTERVAL '16:20' HOUR_MINUTE, 'Falabella, piso 1', 13500, 2000, 15);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (4, 25, 1, 7500), (4, 26, 1, 6000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 4;
UPDATE pedidos SET id_domiciliarioFK = 21 WHERE id_pedido = 4;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 4;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 12 WHERE id_pedido = 4;

-- Pedido 5: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (5, 11, 5, 5, CURDATE() - INTERVAL 11 DAY + INTERVAL '15:45' HOUR_MINUTE, 'Arturo Calle, piso 2', 25000, 5000, 20);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (5, 20, 1, 12000), (5, 21, 1, 13000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 5;
UPDATE pedidos SET id_domiciliarioFK = 6 WHERE id_pedido = 5;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 5;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 24 WHERE id_pedido = 5;

-- Pedido 6: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (6, 12, 1, 1, CURDATE() - INTERVAL 11 DAY + INTERVAL '13:10' HOUR_MINUTE, 'Banco de Bogotá, piso 1', 34000, 3400, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (6, 7, 1, 26000), (6, 9, 1, 8000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 6;
UPDATE pedidos SET id_domiciliarioFK = 22 WHERE id_pedido = 6;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 6;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 21 WHERE id_pedido = 6;

-- Pedido 7: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (7, 13, 4, 4, CURDATE() - INTERVAL 10 DAY + INTERVAL '12:30' HOUR_MINUTE, 'Studio F, piso 2', 39000, 5850, 35);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (7, 16, 1, 24000), (7, 19, 1, 15000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 7;
UPDATE pedidos SET id_domiciliarioFK = 7 WHERE id_pedido = 7;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 7;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 31 WHERE id_pedido = 7;

-- Pedido 8: cancelado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (8, 14, 2, NULL, CURDATE() - INTERVAL 10 DAY + INTERVAL '19:05' HOUR_MINUTE, 'Cine Colombia, piso 3', 43000, 0, 30);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (8, 10, 1, 19000), (8, 11, 1, 24000);
UPDATE pedidos SET estado = 'cancelado' WHERE id_pedido = 8;

-- Pedido 9: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (9, 15, 3, 5, CURDATE() - INTERVAL 9 DAY + INTERVAL '12:50' HOUR_MINUTE, 'Pepe Ganga, piso 1', 34000, 6800, 30);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (9, 14, 1, 22000), (9, 15, 2, 6000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 9;
UPDATE pedidos SET id_domiciliarioFK = 23 WHERE id_pedido = 9;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 9;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 34 WHERE id_pedido = 9;

-- Pedido 10: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (10, 1, 1, NULL, CURDATE() - INTERVAL 9 DAY + INTERVAL '13:20' HOUR_MINUTE, 'Falabella, piso 1', 30000, 0, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (10, 8, 1, 21000), (10, 2, 1, 9000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 10;
UPDATE pedidos SET id_domiciliarioFK = 20 WHERE id_pedido = 10;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 10;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 18 WHERE id_pedido = 10;

-- Pedido 11: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (11, 10, 4, 4, CURDATE() - INTERVAL 8 DAY + INTERVAL '13:00' HOUR_MINUTE, 'Almacenes Éxito, piso 1', 50000, 7500, 35);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (11, 17, 1, 28000), (11, 18, 1, 22000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 11;
UPDATE pedidos SET id_domiciliarioFK = 21 WHERE id_pedido = 11;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 11;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 29 WHERE id_pedido = 11;

-- Pedido 12: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (12, 9, 6, NULL, CURDATE() - INTERVAL 8 DAY + INTERVAL '08:10' HOUR_MINUTE, 'Zara, piso 2', 24000, 0, 15);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (12, 24, 2, 5000), (12, 27, 1, 14000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 12;
UPDATE pedidos SET id_domiciliarioFK = 6 WHERE id_pedido = 12;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 12;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 14 WHERE id_pedido = 12;

-- Pedido 13: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (13, 14, 1, 1, CURDATE() - INTERVAL 7 DAY + INTERVAL '12:20' HOUR_MINUTE, 'Cine Colombia, piso 3', 62000, 6200, 30);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (13, 1, 1, 18000), (13, 7, 1, 26000), (13, 2, 2, 9000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 13;
UPDATE pedidos SET id_domiciliarioFK = 22 WHERE id_pedido = 13;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 13;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 26 WHERE id_pedido = 13;

-- Pedido 14: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (14, 2, 3, 5, CURDATE() - INTERVAL 7 DAY + INTERVAL '12:45' HOUR_MINUTE, 'Cine Colombia, piso 3', 24000, 4800, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (14, 13, 1, 18000), (14, 15, 1, 6000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 14;
UPDATE pedidos SET id_domiciliarioFK = 7 WHERE id_pedido = 14;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 14;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 23 WHERE id_pedido = 14;

-- Pedido 15: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (15, 12, 5, NULL, CURDATE() - INTERVAL 6 DAY + INTERVAL '16:30' HOUR_MINUTE, 'Banco de Bogotá, piso 1', 20000, 0, 20);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (15, 22, 1, 11000), (15, 23, 1, 9000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 15;
UPDATE pedidos SET id_domiciliarioFK = 23 WHERE id_pedido = 15;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 15;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 17 WHERE id_pedido = 15;

-- Pedido 16: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (16, 11, 6, 6, CURDATE() - INTERVAL 6 DAY + INTERVAL '17:00' HOUR_MINUTE, 'Arturo Calle, piso 2', 15000, 2000, 15);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (16, 28, 1, 9000), (16, 26, 1, 6000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 16;
UPDATE pedidos SET id_domiciliarioFK = 20 WHERE id_pedido = 16;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 16;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 16 WHERE id_pedido = 16;

-- Pedido 17: cancelado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (17, 1, 2, NULL, CURDATE() - INTERVAL 5 DAY + INTERVAL '13:15' HOUR_MINUTE, 'Falabella, piso 1', 25500, 0, 30);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (17, 4, 1, 21000), (17, 12, 1, 4500);
UPDATE pedidos SET estado = 'cancelado' WHERE id_pedido = 17;

-- Pedido 18: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (18, 13, 3, 5, CURDATE() - INTERVAL 5 DAY + INTERVAL '12:35' HOUR_MINUTE, 'Studio F, piso 2', 40000, 8000, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (18, 5, 2, 20000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 18;
UPDATE pedidos SET id_domiciliarioFK = 21 WHERE id_pedido = 18;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 18;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 28 WHERE id_pedido = 18;

-- Pedido 19: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (19, 15, 1, NULL, CURDATE() - INTERVAL 4 DAY + INTERVAL '13:40' HOUR_MINUTE, 'Pepe Ganga, piso 1', 29000, 0, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (19, 8, 1, 21000), (19, 9, 1, 8000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 19;
UPDATE pedidos SET id_domiciliarioFK = 6 WHERE id_pedido = 19;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 19;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 20 WHERE id_pedido = 19;

-- Pedido 20: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (20, 10, 2, NULL, CURDATE() - INTERVAL 3 DAY + INTERVAL '19:20' HOUR_MINUTE, 'Almacenes Éxito, piso 1', 50000, 0, 35);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (20, 3, 1, 22000), (20, 10, 1, 19000), (20, 12, 2, 4500);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 20;
UPDATE pedidos SET id_domiciliarioFK = 22 WHERE id_pedido = 20;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 20;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 33 WHERE id_pedido = 20;

-- Pedido 21: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (21, 1, 4, NULL, CURDATE() - INTERVAL 2 DAY + INTERVAL '12:55' HOUR_MINUTE, 'Falabella, piso 1', 37000, 0, 35);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (21, 18, 1, 22000), (21, 19, 1, 15000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 21;
UPDATE pedidos SET id_domiciliarioFK = 7 WHERE id_pedido = 21;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 21;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 30 WHERE id_pedido = 21;

-- Pedido 22: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (22, 9, 5, NULL, CURDATE() - INTERVAL 1 DAY + INTERVAL '15:10' HOUR_MINUTE, 'Zara, piso 2', 13000, 0, 20);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (22, 21, 1, 13000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 22;
UPDATE pedidos SET id_domiciliarioFK = 23 WHERE id_pedido = 22;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 22;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 15 WHERE id_pedido = 22;

-- Pedido 23: entregado
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (23, 14, 6, NULL, CURDATE() - INTERVAL 1 DAY + INTERVAL '10:30' HOUR_MINUTE, 'Cine Colombia, piso 3', 27000, 0, 15);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (23, 25, 2, 7500), (23, 26, 2, 6000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 23;
UPDATE pedidos SET id_domiciliarioFK = 20 WHERE id_pedido = 23;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 23;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 13 WHERE id_pedido = 23;

-- Pedido 24: en_camino
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (24, 12, 1, NULL, NOW() - INTERVAL 22 MINUTE, 'Banco de Bogotá, piso 1', 35000, 0, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (24, 7, 1, 26000), (24, 2, 1, 9000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 24;
UPDATE pedidos SET id_domiciliarioFK = 6 WHERE id_pedido = 24;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 24;

-- Pedido 25: preparando
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (25, 11, 1, NULL, NOW() - INTERVAL 12 MINUTE, 'Arturo Calle, piso 2', 52000, 0, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (25, 1, 2, 18000), (25, 9, 2, 8000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 25;

-- Pedido 26: pendiente
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (26, 10, 1, NULL, NOW() - INTERVAL 4 MINUTE, 'Almacenes Éxito, piso 1', 21000, 0, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (26, 8, 1, 21000);

-- Pedido 27: preparando
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (27, 13, 4, NULL, NOW() - INTERVAL 15 MINUTE, 'Studio F, piso 2', 48000, 0, 35);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (27, 16, 2, 24000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 27;
UPDATE pedidos SET id_domiciliarioFK = 22 WHERE id_pedido = 27;

-- Pedido 28: pendiente
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, fecha_pedido, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (28, 15, 6, NULL, NOW() - INTERVAL 3 MINUTE, 'Pepe Ganga, piso 1', 19000, 0, 15);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (28, 27, 1, 14000), (28, 24, 1, 5000);

-- ---------------------------------------------------------- ajustes finales
-- Productos agotados (después de crear los pedidos antiguos que los incluyen)
UPDATE productos SET disponible = FALSE WHERE id_producto IN (4, 23);

-- El historial se llenó con la hora de ejecución del script: se ajusta a la hora real de cada pedido
UPDATE historial_estado_pedido h
JOIN pedidos p ON p.id_pedido = h.id_pedidoFK
SET h.fecha_hora = p.fecha_pedido + INTERVAL (CASE h.estado
      WHEN 'pendiente'  THEN 0
      WHEN 'preparando' THEN 2
      WHEN 'cancelado'  THEN 3
      WHEN 'en_camino'  THEN LEAST(12, GREATEST(p.tiempo_estimado - 10, 5))
      WHEN 'entregado'  THEN p.tiempo_real
    END) MINUTE;
