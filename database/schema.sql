-- =====================================================================
-- FoodCourt Express - Esquema de base de datos
-- Domicilios de los restaurantes de un centro comercial para sus empleados
-- Motor: MySQL 8.0.16 o superior
--
-- Ejecutar completo en MySQL Workbench (botón del rayo).
-- ATENCIÓN: borra y vuelve a crear la base de datos foodcourt.
-- =====================================================================

DROP DATABASE IF EXISTS foodcourt;
CREATE DATABASE foodcourt
  CHARACTER SET utf8mb4           -- soporta tildes, ñ y emojis
  COLLATE utf8mb4_unicode_ci;
USE foodcourt;

-- =====================================================================
-- 1. CENTROS COMERCIALES
-- =====================================================================
CREATE TABLE centros_comerciales (
  id_centro   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(150) NOT NULL,
  direccion   VARCHAR(255) NOT NULL,
  ciudad      VARCHAR(80)  NOT NULL,
  PRIMARY KEY (id_centro)
) ENGINE = InnoDB;

-- =====================================================================
-- 2. USUARIOS: todas las personas que inician sesión
-- Un solo login para los 4 roles. Los datos propios de cada rol
-- van en las tablas empleados y domiciliarios.
-- =====================================================================
CREATE TABLE usuarios (
  id_usuario         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  primer_nombre      VARCHAR(100) NOT NULL,
  segundo_nombre     VARCHAR(100) NULL,
  primer_apellido    VARCHAR(100) NOT NULL,
  segundo_apellido   VARCHAR(100) NULL,
  documento          VARCHAR(20)  NOT NULL,
  telefono           VARCHAR(20)  NOT NULL,
  correo             VARCHAR(150) NOT NULL,
  contrasenia_hash   VARCHAR(255) NOT NULL,   -- hash bcrypt, NUNCA la contraseña en texto plano
  rol                ENUM('empleado', 'restaurante', 'domiciliario', 'admin') NOT NULL,
  id_foto_perfilFK   INT UNSIGNED NULL,       -- FK a archivos (se agrega más abajo)
  activo             BOOLEAN      NOT NULL DEFAULT TRUE,
  creado_en          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uq_usuarios_correo (correo),
  UNIQUE KEY uq_usuarios_documento (documento)
) ENGINE = InnoDB;

-- =====================================================================
-- 3. ARCHIVOS: metadatos de todo lo que se sube (PERSISTENCIA DUAL)
-- El archivo físico queda en disco o en la nube; aquí solo sus datos.
-- =====================================================================
CREATE TABLE archivos (
  id_archivo          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  nombre_original     VARCHAR(255)    NOT NULL,   -- ej. "hamburguesa.jpg"
  nombre_almacenado   VARCHAR(255)    NOT NULL,   -- ej. "9b1c...e4.jpg" (UUID, evita sobrescribir)
  tipo_mime           VARCHAR(100)    NOT NULL,   -- ej. "image/jpeg"
  peso_bytes          BIGINT UNSIGNED NOT NULL,
  ruta_url            VARCHAR(500)    NOT NULL,   -- ruta en disco o URL en la nube
  categoria           ENUM('foto_producto', 'logo_restaurante', 'foto_perfil',
                           'carne_empleado', 'evidencia_entrega') NOT NULL,
  id_autorFK          INT UNSIGNED    NOT NULL,   -- quién lo subió
  fecha_subida        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_archivo),
  UNIQUE KEY uq_archivos_nombre_almacenado (nombre_almacenado),
  KEY idx_archivos_autor (id_autorFK),
  CONSTRAINT fk_archivo_autor FOREIGN KEY (id_autorFK) REFERENCES usuarios (id_usuario),
  CONSTRAINT chk_archivo_peso CHECK (peso_bytes > 0)
) ENGINE = InnoDB;

ALTER TABLE usuarios
  ADD CONSTRAINT fk_usuario_foto FOREIGN KEY (id_foto_perfilFK)
      REFERENCES archivos (id_archivo) ON DELETE SET NULL;

-- =====================================================================
-- 4. RESTAURANTES
-- =====================================================================
CREATE TABLE restaurantes (
  id_restaurante      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_centroFK         INT UNSIGNED NOT NULL,
  id_administradorFK  INT UNSIGNED NOT NULL,   -- usuario con rol 'restaurante' que lo gestiona
  nombre_restaurante  VARCHAR(150) NOT NULL,
  categoria           VARCHAR(60)  NOT NULL,   -- ej. "Hamburguesas", "Comida típica"
  local               VARCHAR(20)  NOT NULL,   -- ej. "214"
  piso                TINYINT      NOT NULL,
  telefono            VARCHAR(20)  NOT NULL,
  hora_apertura       TIME         NOT NULL,
  hora_cierre         TIME         NOT NULL,
  id_logoFK           INT UNSIGNED NULL,
  activo              BOOLEAN      NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id_restaurante),
  UNIQUE KEY uq_restaurante_local (id_centroFK, local),   -- dos restaurantes no comparten local
  KEY idx_restaurante_admin (id_administradorFK),
  KEY idx_restaurante_logo (id_logoFK),
  CONSTRAINT fk_restaurante_centro FOREIGN KEY (id_centroFK)        REFERENCES centros_comerciales (id_centro),
  CONSTRAINT fk_restaurante_admin  FOREIGN KEY (id_administradorFK) REFERENCES usuarios (id_usuario),
  CONSTRAINT fk_restaurante_logo   FOREIGN KEY (id_logoFK)          REFERENCES archivos (id_archivo) ON DELETE SET NULL,
  CONSTRAINT chk_restaurante_horario CHECK (hora_cierre > hora_apertura)
) ENGINE = InnoDB;

-- =====================================================================
-- 5. EMPLEADOS: los clientes (solo empleados registrados pueden pedir)
-- =====================================================================
CREATE TABLE empleados (
  id_usuarioFK       INT UNSIGNED NOT NULL,   -- misma llave que usuarios (relación 1 a 1)
  id_centroFK        INT UNSIGNED NOT NULL,
  local_trabajo      VARCHAR(100) NOT NULL,   -- ej. "Falabella, piso 1"
  id_carneFK         INT UNSIGNED NULL,       -- foto del carné para verificar que trabaja ahí
  verificado         BOOLEAN      NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_usuarioFK),
  KEY idx_empleado_centro (id_centroFK),
  KEY idx_empleado_carne (id_carneFK),
  CONSTRAINT fk_empleado_usuario FOREIGN KEY (id_usuarioFK) REFERENCES usuarios (id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_empleado_centro  FOREIGN KEY (id_centroFK)  REFERENCES centros_comerciales (id_centro),
  CONSTRAINT fk_empleado_carne   FOREIGN KEY (id_carneFK)   REFERENCES archivos (id_archivo) ON DELETE SET NULL
) ENGINE = InnoDB;

-- =====================================================================
-- 6. DOMICILIARIOS
-- =====================================================================
CREATE TABLE domiciliarios (
  id_usuarioFK     INT UNSIGNED NOT NULL,
  tipo_vehiculo    ENUM('moto', 'bicicleta', 'patineta', 'a_pie') NOT NULL,
  placa_vehiculo   VARCHAR(10)  NULL,          -- solo aplica a motos
  disponible       BOOLEAN      NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id_usuarioFK),
  UNIQUE KEY uq_domiciliario_placa (placa_vehiculo),
  CONSTRAINT fk_domiciliario_usuario FOREIGN KEY (id_usuarioFK) REFERENCES usuarios (id_usuario) ON DELETE CASCADE,
  CONSTRAINT chk_domiciliario_placa CHECK (tipo_vehiculo <> 'moto' OR placa_vehiculo IS NOT NULL)
) ENGINE = InnoDB;

-- =====================================================================
-- 7. PRODUCTOS
-- =====================================================================
CREATE TABLE productos (
  id_producto        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  id_restauranteFK   INT UNSIGNED  NOT NULL,
  nombre_producto    VARCHAR(150)  NOT NULL,
  descripcion        TEXT          NOT NULL,
  precio             DECIMAL(10,2) NOT NULL,
  disponible         BOOLEAN       NOT NULL DEFAULT TRUE,
  id_fotoFK          INT UNSIGNED  NULL,
  creado_en          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_producto),
  KEY idx_producto_restaurante (id_restauranteFK, disponible),
  KEY idx_producto_foto (id_fotoFK),
  CONSTRAINT fk_producto_restaurante FOREIGN KEY (id_restauranteFK) REFERENCES restaurantes (id_restaurante),
  CONSTRAINT fk_producto_foto        FOREIGN KEY (id_fotoFK)        REFERENCES archivos (id_archivo) ON DELETE SET NULL,
  CONSTRAINT chk_producto_precio CHECK (precio > 0)
) ENGINE = InnoDB;

-- =====================================================================
-- 8. CUPONES
-- =====================================================================
CREATE TABLE cupones (
  id_cupon           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  codigo             VARCHAR(50)   NOT NULL,
  tipo               ENUM('porcentaje', 'valor_fijo') NOT NULL,
  valor              DECIMAL(10,2) NOT NULL,   -- 10 = 10 % si es porcentaje, o $10 si es valor fijo
  fecha_inicio       DATE          NOT NULL,
  fecha_fin          DATE          NOT NULL,
  usos_maximos       INT UNSIGNED  NOT NULL,
  id_restauranteFK   INT UNSIGNED  NULL,       -- NULL = válido en todos los restaurantes
  condiciones        VARCHAR(255)  NULL,
  PRIMARY KEY (id_cupon),
  UNIQUE KEY uq_cupon_codigo (codigo),
  KEY idx_cupon_restaurante (id_restauranteFK),
  CONSTRAINT fk_cupon_restaurante FOREIGN KEY (id_restauranteFK) REFERENCES restaurantes (id_restaurante),
  CONSTRAINT chk_cupon_valor      CHECK (valor > 0),
  CONSTRAINT chk_cupon_porcentaje CHECK (tipo <> 'porcentaje' OR valor <= 100),
  CONSTRAINT chk_cupon_fechas     CHECK (fecha_fin >= fecha_inicio),
  CONSTRAINT chk_cupon_usos       CHECK (usos_maximos > 0)
) ENGINE = InnoDB;

-- Relación N:M empleado - cupón (cupones asignados a cada empleado)
CREATE TABLE empleado_cupon (
  id_empleadoFK      INT UNSIGNED NOT NULL,
  id_cuponFK         INT UNSIGNED NOT NULL,
  fecha_asignacion   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usado              BOOLEAN      NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_empleadoFK, id_cuponFK),
  KEY idx_empleado_cupon_cupon (id_cuponFK),
  CONSTRAINT fk_ec_empleado FOREIGN KEY (id_empleadoFK) REFERENCES empleados (id_usuarioFK) ON DELETE CASCADE,
  CONSTRAINT fk_ec_cupon    FOREIGN KEY (id_cuponFK)    REFERENCES cupones (id_cupon)       ON DELETE CASCADE
) ENGINE = InnoDB;

-- =====================================================================
-- 9. PEDIDOS
-- =====================================================================
CREATE TABLE pedidos (
  id_pedido          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  id_empleadoFK      INT UNSIGNED  NOT NULL,
  id_restauranteFK   INT UNSIGNED  NOT NULL,   -- un pedido = un solo restaurante
  id_domiciliarioFK  INT UNSIGNED  NULL,       -- se asigna después de crear el pedido
  id_cuponFK         INT UNSIGNED  NULL,       -- el cupón es opcional
  fecha_pedido       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  punto_entrega      VARCHAR(255)  NOT NULL,   -- ej. "Piso 2, local 214"
  subtotal           DECIMAL(10,2) NOT NULL DEFAULT 0,
  descuento          DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_total        DECIMAL(10,2) GENERATED ALWAYS AS (subtotal - descuento) STORED,
  estado             ENUM('pendiente', 'preparando', 'en_camino', 'entregado', 'cancelado')
                     NOT NULL DEFAULT 'pendiente',
  tiempo_estimado    SMALLINT UNSIGNED NULL,   -- minutos
  tiempo_real        SMALLINT UNSIGNED NULL,   -- minutos, se llena al entregar
  id_evidenciaFK     INT UNSIGNED  NULL,       -- foto de la entrega tomada por el domiciliario
  PRIMARY KEY (id_pedido),
  KEY idx_pedido_empleado (id_empleadoFK, fecha_pedido),
  KEY idx_pedido_restaurante (id_restauranteFK, estado),
  KEY idx_pedido_domiciliario (id_domiciliarioFK, estado),
  KEY idx_pedido_cupon (id_cuponFK),
  KEY idx_pedido_evidencia (id_evidenciaFK),
  CONSTRAINT fk_pedido_empleado     FOREIGN KEY (id_empleadoFK)     REFERENCES empleados (id_usuarioFK),
  CONSTRAINT fk_pedido_restaurante  FOREIGN KEY (id_restauranteFK)  REFERENCES restaurantes (id_restaurante),
  CONSTRAINT fk_pedido_domiciliario FOREIGN KEY (id_domiciliarioFK) REFERENCES domiciliarios (id_usuarioFK),
  CONSTRAINT fk_pedido_cupon        FOREIGN KEY (id_cuponFK)        REFERENCES cupones (id_cupon),
  CONSTRAINT fk_pedido_evidencia    FOREIGN KEY (id_evidenciaFK)    REFERENCES archivos (id_archivo) ON DELETE SET NULL,
  CONSTRAINT chk_pedido_montos      CHECK (subtotal >= 0 AND descuento >= 0 AND descuento <= subtotal)
) ENGINE = InnoDB;

-- Relación N:M pedido - producto
CREATE TABLE detalle_pedidos (
  id_pedidoFK       INT UNSIGNED  NOT NULL,
  id_productoFK     INT UNSIGNED  NOT NULL,
  cantidad          SMALLINT UNSIGNED NOT NULL,
  precio_unitario   DECIMAL(10,2) NOT NULL,   -- precio congelado al momento de la compra
  subtotal          DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
  PRIMARY KEY (id_pedidoFK, id_productoFK),  -- un producto aparece una sola vez por pedido
  KEY idx_detalle_producto (id_productoFK),
  CONSTRAINT fk_detalle_pedido   FOREIGN KEY (id_pedidoFK)   REFERENCES pedidos (id_pedido) ON DELETE CASCADE,
  CONSTRAINT fk_detalle_producto FOREIGN KEY (id_productoFK) REFERENCES productos (id_producto),
  CONSTRAINT chk_detalle_cantidad CHECK (cantidad > 0)
) ENGINE = InnoDB;

-- =====================================================================
-- 10. HISTORIAL DE ESTADOS (se llena automáticamente con triggers)
-- =====================================================================
CREATE TABLE historial_estado_pedido (
  id_historial       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_pedidoFK        INT UNSIGNED NOT NULL,
  estado             ENUM('pendiente', 'preparando', 'en_camino', 'entregado', 'cancelado') NOT NULL,
  id_domiciliarioFK  INT UNSIGNED NULL,       -- domiciliario asignado en ese momento (si hay)
  fecha_hora         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_historial),
  KEY idx_historial_pedido (id_pedidoFK, fecha_hora),
  KEY idx_historial_domiciliario (id_domiciliarioFK),
  CONSTRAINT fk_historial_pedido       FOREIGN KEY (id_pedidoFK)       REFERENCES pedidos (id_pedido) ON DELETE CASCADE,
  CONSTRAINT fk_historial_domiciliario FOREIGN KEY (id_domiciliarioFK) REFERENCES domiciliarios (id_usuarioFK)
) ENGINE = InnoDB;


-- =====================================================================
-- TRIGGERS: las reglas de negocio del documento, garantizadas por la BD
-- =====================================================================
DELIMITER $$

-- REGLAS: cupón vigente, asignado al empleado, sin usar, con usos disponibles
--         y válido en ese restaurante.
CREATE TRIGGER trg_pedido_validar_cupon
BEFORE INSERT ON pedidos
FOR EACH ROW
BEGIN
  DECLARE v_inicio DATE;
  DECLARE v_fin DATE;
  DECLARE v_max INT;
  DECLARE v_rest INT;

  IF NEW.id_cuponFK IS NOT NULL THEN
    SELECT fecha_inicio, fecha_fin, usos_maximos, id_restauranteFK
      INTO v_inicio, v_fin, v_max, v_rest
      FROM cupones WHERE id_cupon = NEW.id_cuponFK;

    IF CURDATE() NOT BETWEEN v_inicio AND v_fin THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cupón no está vigente';
    END IF;

    IF v_rest IS NOT NULL AND v_rest <> NEW.id_restauranteFK THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cupón no es válido en este restaurante';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM empleado_cupon
                   WHERE id_empleadoFK = NEW.id_empleadoFK
                     AND id_cuponFK = NEW.id_cuponFK AND usado = FALSE) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El empleado no tiene este cupón asignado o ya lo usó';
    END IF;

    IF (SELECT COUNT(*) FROM pedidos
        WHERE id_cuponFK = NEW.id_cuponFK AND estado <> 'cancelado') >= v_max THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cupón alcanzó su número máximo de usos';
    END IF;
  END IF;
END$$

-- Al crear el pedido: se registra el primer estado y se marca el cupón como usado.
CREATE TRIGGER trg_pedido_creado
AFTER INSERT ON pedidos
FOR EACH ROW
BEGIN
  INSERT INTO historial_estado_pedido (id_pedidoFK, estado, id_domiciliarioFK)
  VALUES (NEW.id_pedido, NEW.estado, NEW.id_domiciliarioFK);

  IF NEW.id_cuponFK IS NOT NULL THEN
    UPDATE empleado_cupon SET usado = TRUE
    WHERE id_empleadoFK = NEW.id_empleadoFK AND id_cuponFK = NEW.id_cuponFK;
  END IF;
END$$

-- REGLAS: el estado sigue el flujo pendiente → preparando → en_camino → entregado
--         (se puede cancelar antes de salir), y solo se asigna un domiciliario disponible.
CREATE TRIGGER trg_pedido_validar_cambios
BEFORE UPDATE ON pedidos
FOR EACH ROW
BEGIN
  IF NEW.estado <> OLD.estado AND NOT (
       (OLD.estado = 'pendiente'  AND NEW.estado IN ('preparando', 'cancelado')) OR
       (OLD.estado = 'preparando' AND NEW.estado IN ('en_camino',  'cancelado')) OR
       (OLD.estado = 'en_camino'  AND NEW.estado = 'entregado')
     ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cambio de estado no permitido';
  END IF;

  IF NEW.estado = 'en_camino' AND NEW.id_domiciliarioFK IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Asigna un domiciliario antes de enviar el pedido';
  END IF;

  IF NEW.id_domiciliarioFK IS NOT NULL
     AND NOT (NEW.id_domiciliarioFK <=> OLD.id_domiciliarioFK)
     AND (SELECT disponible FROM domiciliarios WHERE id_usuarioFK = NEW.id_domiciliarioFK) = FALSE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El domiciliario no está disponible';
  END IF;
END$$

-- Cada cambio de estado queda en el historial, y la disponibilidad del domiciliario se actualiza sola.
CREATE TRIGGER trg_pedido_actualizado
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
  IF NEW.estado <> OLD.estado THEN
    INSERT INTO historial_estado_pedido (id_pedidoFK, estado, id_domiciliarioFK)
    VALUES (NEW.id_pedido, NEW.estado, NEW.id_domiciliarioFK);
  END IF;

  -- Al asignarle un pedido, el domiciliario queda ocupado
  IF NEW.id_domiciliarioFK IS NOT NULL AND NOT (NEW.id_domiciliarioFK <=> OLD.id_domiciliarioFK) THEN
    UPDATE domiciliarios SET disponible = FALSE WHERE id_usuarioFK = NEW.id_domiciliarioFK;
  END IF;

  -- Al entregar o cancelar, vuelve a quedar disponible
  IF NEW.estado IN ('entregado', 'cancelado') AND NEW.estado <> OLD.estado
     AND NEW.id_domiciliarioFK IS NOT NULL THEN
    UPDATE domiciliarios SET disponible = TRUE WHERE id_usuarioFK = NEW.id_domiciliarioFK;
  END IF;
END$$

-- REGLA: todos los productos de un pedido son del mismo restaurante y están disponibles.
CREATE TRIGGER trg_detalle_validar_producto
BEFORE INSERT ON detalle_pedidos
FOR EACH ROW
BEGIN
  IF (SELECT id_restauranteFK FROM productos WHERE id_producto = NEW.id_productoFK)
     <> (SELECT id_restauranteFK FROM pedidos WHERE id_pedido = NEW.id_pedidoFK) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Todos los productos deben ser del mismo restaurante';
  END IF;

  IF (SELECT disponible FROM productos WHERE id_producto = NEW.id_productoFK) = FALSE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto está agotado';
  END IF;
END$$

DELIMITER ;
