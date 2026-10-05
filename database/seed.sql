-- =====================================================================
-- FoodCourt Express - Datos de prueba
-- Ejecutar DESPUÉS de schema.sql
-- Coinciden con los datos de demostración de la app (App.js).
-- =====================================================================
USE foodcourt;

INSERT INTO centros_comerciales (nombre, direccion, ciudad) VALUES
  ('Centro Comercial Unicentro', 'Carrera 100 # 5-169', 'Cali');

-- Usuarios. En el Avance 2 el backend reemplaza 'HASH_PENDIENTE' por hashes bcrypt reales.
INSERT INTO usuarios (id_usuario, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido,
                      documento, telefono, correo, contrasenia_hash, rol) VALUES
  (1, 'Ana',    'María', 'Gómez',    'Ruiz',    '1144000001', '3001000001', 'ana@centro.com',          'HASH_PENDIENTE', 'empleado'),
  (2, 'Julián', NULL,    'Torres',   NULL,      '1144000002', '3001000002', 'julian@centro.com',       'HASH_PENDIENTE', 'empleado'),
  (3, 'Pedro',  NULL,    'Ramírez',  'López',   '1144000003', '3001000003', 'burger@foodcourt.co',     'HASH_PENDIENTE', 'restaurante'),
  (4, 'Lucía',  NULL,    'Moreno',   NULL,      '1144000004', '3001000004', 'pizza@foodcourt.co',      'HASH_PENDIENTE', 'restaurante'),
  (5, 'Rosa',   'Elena', 'Valencia', NULL,      '1144000005', '3001000005', 'criollo@foodcourt.co',    'HASH_PENDIENTE', 'restaurante'),
  (6, 'Andrés', NULL,    'Castillo', 'Mejía',   '1144000006', '3001000006', 'andres@foodcourt.co',     'HASH_PENDIENTE', 'domiciliario'),
  (7, 'Camila', NULL,    'Rojas',    NULL,      '1144000007', '3001000007', 'camila@foodcourt.co',     'HASH_PENDIENTE', 'domiciliario'),
  (8, 'Admin',  NULL,    'Sistema',  NULL,      '1144000008', '3001000008', 'admin@foodcourt.co',      'HASH_PENDIENTE', 'admin');

INSERT INTO empleados (id_usuarioFK, id_centroFK, local_trabajo, verificado) VALUES
  (1, 1, 'Falabella, piso 1', TRUE),
  (2, 1, 'Cine Colombia, piso 3', TRUE);

INSERT INTO domiciliarios (id_usuarioFK, tipo_vehiculo, placa_vehiculo, disponible) VALUES
  (6, 'bicicleta', NULL,     TRUE),
  (7, 'patineta',  NULL,     TRUE);

INSERT INTO restaurantes (id_restaurante, id_centroFK, id_administradorFK, nombre_restaurante, categoria,
                          local, piso, telefono, hora_apertura, hora_cierre) VALUES
  (1, 1, 3, 'Burger House',  'Hamburguesas',  '301', 3, '6023000001', '10:00', '21:00'),
  (2, 1, 4, 'Pizza Piazza',  'Pizzería',      '305', 3, '6023000002', '11:00', '22:00'),
  (3, 1, 5, 'Sabor Criollo', 'Comida típica', '310', 3, '6023000003', '08:00', '20:00');

-- Fotos de productos (solo metadatos; el archivo estaría en backend/uploads/productos/)
INSERT INTO archivos (id_archivo, nombre_original, nombre_almacenado, tipo_mime, peso_bytes, ruta_url, categoria, id_autorFK) VALUES
  (1, 'hamburguesa clasica.jpg', 'a1f0c3d2-0001-4b7e-9c1a-000000000001.jpg', 'image/jpeg', 245760, 'uploads/productos/a1f0c3d2-0001-4b7e-9c1a-000000000001.jpg', 'foto_producto', 3),
  (2, 'papas.jpg',               'a1f0c3d2-0002-4b7e-9c1a-000000000002.jpg', 'image/jpeg', 198400, 'uploads/productos/a1f0c3d2-0002-4b7e-9c1a-000000000002.jpg', 'foto_producto', 3),
  (3, 'pepperoni.jpg',           'a1f0c3d2-0003-4b7e-9c1a-000000000003.jpg', 'image/jpeg', 301000, 'uploads/productos/a1f0c3d2-0003-4b7e-9c1a-000000000003.jpg', 'foto_producto', 4);

INSERT INTO productos (id_producto, id_restauranteFK, nombre_producto, descripcion, precio, disponible, id_fotoFK) VALUES
  (1, 1, 'Hamburguesa clásica', 'Carne 150 g, queso, lechuga y tomate.',      18000, TRUE,  1),
  (2, 1, 'Papas criollas',      'Porción grande con salsas de la casa.',      9000,  TRUE,  2),
  (3, 2, 'Pizza pepperoni',     'Personal de 6 porciones.',                   22000, TRUE,  3),
  (4, 2, 'Pizza hawaiana',      'Jamón y piña sobre masa artesanal.',         21000, FALSE, NULL),
  (5, 3, 'Bandeja del día',     'Arroz, fríjoles, carne, plátano y huevo.',   20000, TRUE,  NULL),
  (6, 3, 'Sopa de pollo',       'Con papa, yuca y arroz aparte.',             14000, TRUE,  NULL);

-- Cupones: las fechas se calculan desde hoy para que siempre estén vigentes al probar
INSERT INTO cupones (id_cupon, codigo, tipo, valor, fecha_inicio, fecha_fin, usos_maximos, id_restauranteFK, condiciones) VALUES
  (1, 'EMPLEADO10', 'porcentaje', 10,   CURDATE() - INTERVAL 30 DAY, CURDATE() + INTERVAL 90 DAY, 100, NULL, '10 % de descuento en cualquier restaurante'),
  (2, 'PROMO5000',  'valor_fijo', 5000, CURDATE() - INTERVAL 30 DAY, CURDATE() + INTERVAL 90 DAY, 50,   2,    '$5.000 de descuento en Pizza Piazza'),
  (3, 'VENCIDO20',  'porcentaje', 20,   CURDATE() - INTERVAL 60 DAY, CURDATE() - INTERVAL 1 DAY,  100, NULL, 'Cupón vencido, para pruebas');

INSERT INTO empleado_cupon (id_empleadoFK, id_cuponFK) VALUES
  (1, 1), (1, 2), (1, 3),
  (2, 1);

-- Un pedido de ejemplo que recorre todo el flujo (el historial se llena solo con los triggers)
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, punto_entrega, subtotal, descuento, tiempo_estimado)
VALUES (1, 2, 1, 1, 'Cine Colombia, taquilla, piso 3', 45000, 4500, 25);
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES
  (1, 1, 2, 18000),
  (1, 2, 1, 9000);
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 1;
UPDATE pedidos SET id_domiciliarioFK = 6 WHERE id_pedido = 1;
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 1;

INSERT INTO archivos (id_archivo, nombre_original, nombre_almacenado, tipo_mime, peso_bytes, ruta_url, categoria, id_autorFK) VALUES
  (4, 'IMG_2041.jpg', 'e7b2d9f1-0004-4c2a-8d3e-000000000004.jpg', 'image/jpeg', 512000, 'uploads/entregas/e7b2d9f1-0004-4c2a-8d3e-000000000004.jpg', 'evidencia_entrega', 6);
UPDATE pedidos SET estado = 'entregado', tiempo_real = 22, id_evidenciaFK = 4 WHERE id_pedido = 1;
