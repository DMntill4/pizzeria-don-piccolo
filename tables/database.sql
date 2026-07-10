-- =====================================================================
-- PIZZERÍA DON PICCOLO - Script de creación de base de datos
-- =====================================================================

DROP DATABASE IF EXISTS pizzeria_don_piccolo;
CREATE DATABASE pizzeria_don_piccolo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pizzeria_don_piccolo;

-- ---------------------------------------------------------------------
-- Tabla: clientes
-- ---------------------------------------------------------------------
CREATE TABLE clientes (
    id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    telefono        VARCHAR(20)  NOT NULL,
    direccion       VARCHAR(200) NOT NULL,
    correo          VARCHAR(100),
    fecha_registro  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: ingredientes
-- ---------------------------------------------------------------------
CREATE TABLE ingredientes (
    id_ingrediente  INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    unidad_medida   VARCHAR(20)  NOT NULL,      -- gramos, unidades, ml
    stock_actual    DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_minimo    DECIMAL(10,2) NOT NULL DEFAULT 0,
    costo_unitario  DECIMAL(10,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: pizzas
-- ---------------------------------------------------------------------
CREATE TABLE pizzas (
    id_pizza     INT AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    tamano       ENUM('Personal','Mediana','Grande','Familiar') NOT NULL,
    precio_base  DECIMAL(10,2) NOT NULL,
    tipo         ENUM('Vegetariana','Especial','Clasica') NOT NULL,
    activo       TINYINT(1) DEFAULT 1
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: pizza_ingredientes (receta -> relación N:M)
-- ---------------------------------------------------------------------
CREATE TABLE pizza_ingredientes (
    id_pizza            INT NOT NULL,
    id_ingrediente      INT NOT NULL,
    cantidad_requerida  DECIMAL(10,2) NOT NULL,  -- cantidad por unidad de pizza
    PRIMARY KEY (id_pizza, id_ingrediente),
    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza) ON DELETE CASCADE,
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes(id_ingrediente) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: repartidores
-- ---------------------------------------------------------------------
CREATE TABLE repartidores (
    id_repartidor  INT AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    zona_asignada  VARCHAR(50) NOT NULL,
    estado         ENUM('Disponible','No disponible') DEFAULT 'Disponible'
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: pedidos
-- ---------------------------------------------------------------------
CREATE TABLE pedidos (
    id_pedido    INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente   INT NOT NULL,
    fecha_hora   DATETIME DEFAULT CURRENT_TIMESTAMP,
    metodo_pago  ENUM('Efectivo','Tarjeta','App') NOT NULL,
    estado       ENUM('Pendiente','En preparacion','Entregado','Cancelado') DEFAULT 'Pendiente',
    total        DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: pedido_detalle (pizzas solicitadas en cada pedido)
-- ---------------------------------------------------------------------
CREATE TABLE pedido_detalle (
    id_detalle       INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido        INT NOT NULL,
    id_pizza         INT NOT NULL,
    cantidad         INT NOT NULL DEFAULT 1,
    precio_unitario  DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_pizza)  REFERENCES pizzas(id_pizza)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: domicilios
-- ---------------------------------------------------------------------
CREATE TABLE domicilios (
    id_domicilio   INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido      INT NOT NULL UNIQUE,
    id_repartidor  INT,
    hora_salida    DATETIME,
    hora_entrega   DATETIME,
    distancia_km   DECIMAL(6,2),
    costo_envio    DECIMAL(10,2),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: pagos
-- ---------------------------------------------------------------------
CREATE TABLE pagos (
    id_pago      INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido    INT NOT NULL,
    monto        DECIMAL(10,2) NOT NULL,
    metodo_pago  ENUM('Efectivo','Tarjeta','App') NOT NULL,
    fecha_pago   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Tabla: historial_precios (auditoría de cambios de precio de pizzas)
-- ---------------------------------------------------------------------
CREATE TABLE historial_precios (
    id_historial     INT AUTO_INCREMENT PRIMARY KEY,
    id_pizza         INT NOT NULL,
    precio_anterior  DECIMAL(10,2) NOT NULL,
    precio_nuevo     DECIMAL(10,2) NOT NULL,
    fecha_cambio     DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza)
) ENGINE=InnoDB;

-- =====================================================================
-- DATOS DE PRUEBA (opcional, para probar funciones/triggers/vistas)
-- =====================================================================

INSERT INTO clientes (nombre, telefono, direccion, correo) VALUES
('Laura Gómez', '3001112233', 'Cra 10 # 20-30', 'laura@mail.com'),
('Carlos Pérez', '3002223344', 'Cl 45 # 12-08', 'carlos@mail.com'),
('Ana Torres', '3003334455', 'Av Libertad # 5-60', 'ana@mail.com');

INSERT INTO ingredientes (nombre, unidad_medida, stock_actual, stock_minimo, costo_unitario) VALUES
('Masa', 'unidades', 100, 20, 1500),
('Queso Mozzarella', 'gramos', 5000, 1000, 20),
('Salsa de tomate', 'gramos', 4000, 800, 10),
('Pepperoni', 'gramos', 3000, 500, 30),
('Champiñones', 'gramos', 2000, 400, 15),
('Pimentón', 'gramos', 1500, 300, 8);

INSERT INTO pizzas (nombre, tamano, precio_base, tipo) VALUES
('Pepperoni Clásica', 'Grande', 35000, 'Clasica'),
('Vegetariana Especial', 'Grande', 32000, 'Vegetariana'),
('Don Piccolo Especial', 'Familiar', 45000, 'Especial');

INSERT INTO pizza_ingredientes (id_pizza, id_ingrediente, cantidad_requerida) VALUES
(1, 1, 1), (1, 2, 200), (1, 3, 100), (1, 4, 80),
(2, 1, 1), (2, 2, 200), (2, 3, 100), (2, 5, 60), (2, 6, 40),
(3, 1, 1), (3, 2, 250), (3, 3, 120), (3, 4, 60), (3, 5, 40);

INSERT INTO repartidores (nombre, zona_asignada, estado) VALUES
('Jorge Ramírez', 'Norte', 'Disponible'),
('Pedro Suárez', 'Sur', 'Disponible');

-- Pedido de ejemplo
INSERT INTO pedidos (id_cliente, metodo_pago, estado) VALUES (1, 'Efectivo', 'Pendiente');
INSERT INTO pedido_detalle (id_pedido, id_pizza, cantidad, precio_unitario) VALUES (1, 1, 2, 35000);
INSERT INTO domicilios (id_pedido, id_repartidor, distancia_km, costo_envio)
VALUES (1, 1, 4.5, 6000);