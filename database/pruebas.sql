-- =====================================================================
-- FoodCourt Express - Pruebas de las reglas de negocio
-- Ejecutar DESPUÉS de schema.sql y seed.sql.
-- En Workbench: poner el cursor sobre cada consulta y presionar Ctrl + Enter.
-- Las pruebas marcadas con "debe FALLAR" muestran un error: eso es lo correcto.
-- =====================================================================
USE foodcourt;

-- ---------- Regla: un pedido = un solo restaurante ----------
-- Ana (id 1) crea un pedido en Burger House (restaurante 1)
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, punto_entrega, subtotal)
VALUES (100, 1, 1, 'Falabella, piso 1, caja 3', 18000);

-- PRUEBA 1 - debe FUNCIONAR: hamburguesa de Burger House
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (100, 1, 1, 18000);

-- PRUEBA 2 - debe FALLAR: pizza de otro restaurante en el mismo pedido
-- Error esperado: "Todos los productos deben ser del mismo restaurante"
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (100, 3, 1, 22000);

-- ---------- Regla: no se venden productos agotados ----------
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, punto_entrega, subtotal)
VALUES (101, 1, 2, 'Falabella, piso 1', 21000);
-- PRUEBA 3 - debe FALLAR: la pizza hawaiana está agotada
-- Error esperado: "El producto está agotado"
INSERT INTO detalle_pedidos (id_pedidoFK, id_productoFK, cantidad, precio_unitario) VALUES (101, 4, 1, 21000);

-- ---------- Reglas de cupones ----------
-- PRUEBA 4 - debe FALLAR: cupón vencido
-- Error esperado: "El cupón no está vigente"
INSERT INTO pedidos (id_empleadoFK, id_restauranteFK, id_cuponFK, punto_entrega, subtotal, descuento)
VALUES (1, 1, 3, 'Falabella, piso 1', 18000, 3600);

-- PRUEBA 5 - debe FALLAR: PROMO5000 solo sirve en Pizza Piazza
-- Error esperado: "El cupón no es válido en este restaurante"
INSERT INTO pedidos (id_empleadoFK, id_restauranteFK, id_cuponFK, punto_entrega, subtotal, descuento)
VALUES (1, 1, 2, 'Falabella, piso 1', 18000, 5000);

-- PRUEBA 6 - debe FALLAR: Julián (id 2) ya usó su cupón EMPLEADO10 en el pedido del seed
-- Error esperado: "El empleado no tiene este cupón asignado o ya lo usó"
INSERT INTO pedidos (id_empleadoFK, id_restauranteFK, id_cuponFK, punto_entrega, subtotal, descuento)
VALUES (2, 3, 1, 'Cine Colombia, piso 3', 20000, 2000);

-- PRUEBA 7 - debe FUNCIONAR: Ana usa PROMO5000 en Pizza Piazza (queda marcado como usado)
INSERT INTO pedidos (id_pedido, id_empleadoFK, id_restauranteFK, id_cuponFK, punto_entrega, subtotal, descuento)
VALUES (102, 1, 2, 2, 'Falabella, piso 1', 22000, 5000);

-- ---------- Regla: flujo de estados ----------
-- PRUEBA 8 - debe FALLAR: no se puede pasar de pendiente a entregado
-- Error esperado: "Cambio de estado no permitido"
UPDATE pedidos SET estado = 'entregado' WHERE id_pedido = 100;

-- PRUEBA 9 - debe FALLAR: no puede salir "en camino" sin domiciliario
UPDATE pedidos SET estado = 'preparando' WHERE id_pedido = 100;   -- este paso sí funciona
UPDATE pedidos SET estado = 'en_camino'  WHERE id_pedido = 100;   -- este falla

-- ---------- Regla: solo domiciliarios disponibles ----------
-- PRUEBA 10 - debe FUNCIONAR: se asigna a Camila (id 7); queda ocupada automáticamente
UPDATE pedidos SET id_domiciliarioFK = 7 WHERE id_pedido = 100;

-- PRUEBA 11 - debe FALLAR: Camila ya está ocupada con el pedido 100
-- Error esperado: "El domiciliario no está disponible"
UPDATE pedidos SET id_domiciliarioFK = 7 WHERE id_pedido = 102;

-- PRUEBA 12 - debe FUNCIONAR: el pedido 100 sale y se entrega; Camila vuelve a quedar disponible
UPDATE pedidos SET estado = 'en_camino' WHERE id_pedido = 100;
UPDATE pedidos SET estado = 'entregado', tiempo_real = 18 WHERE id_pedido = 100;

-- ---------- Restricciones de datos ----------
-- PRUEBA 13 - debe FALLAR: correo repetido
INSERT INTO usuarios (primer_nombre, primer_apellido, documento, telefono, correo, contrasenia_hash, rol)
VALUES ('Otra', 'Persona', '1144999999', '3009999999', 'ana@centro.com', 'HASH_PENDIENTE', 'empleado');

-- PRUEBA 14 - debe FALLAR: un cupón de porcentaje no puede ser mayor a 100 %
INSERT INTO cupones (codigo, tipo, valor, fecha_inicio, fecha_fin, usos_maximos)
VALUES ('MITAD150', 'porcentaje', 150, CURDATE(), CURDATE() + INTERVAL 10 DAY, 10);

-- ---------- Consultas para revisar los resultados ----------
-- Historial completo del pedido 100 (se generó solo con los triggers)
SELECT h.estado, h.fecha_hora, CONCAT(u.primer_nombre, ' ', u.primer_apellido) AS domiciliario
FROM historial_estado_pedido h
LEFT JOIN usuarios u ON u.id_usuario = h.id_domiciliarioFK
WHERE h.id_pedidoFK = 100
ORDER BY h.id_historial;

-- Productos con su foto (persistencia dual: los datos del archivo vienen de la tabla archivos)
SELECT r.nombre_restaurante, p.nombre_producto, p.precio, p.disponible,
       a.nombre_original, a.ruta_url, a.peso_bytes
FROM productos p
JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
LEFT JOIN archivos a ON a.id_archivo = p.id_fotoFK
ORDER BY r.nombre_restaurante, p.nombre_producto;

-- Pedidos de Ana con su total (lo que vería en "Mis pedidos")
SELECT p.id_pedido, r.nombre_restaurante, p.fecha_pedido, p.subtotal, p.descuento, p.valor_total, p.estado
FROM pedidos p
JOIN restaurantes r ON r.id_restaurante = p.id_restauranteFK
WHERE p.id_empleadoFK = 1
ORDER BY p.fecha_pedido DESC;
