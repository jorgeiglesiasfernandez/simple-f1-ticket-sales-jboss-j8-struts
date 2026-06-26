-- =====================================================
-- Schema SQL para F1 Tickets - MySQL 8.0
-- Base de datos: f1_tickets
-- =====================================================

-- Usar la base de datos
USE f1_tickets;

-- Tabla de Eventos
CREATE TABLE IF NOT EXISTS events (
    id VARCHAR(50) PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    fecha DATETIME NOT NULL,
    circuito VARCHAR(200) NOT NULL,
    ubicacion VARCHAR(200) NOT NULL,
    capacidad_total INT NOT NULL DEFAULT 1000,
    entradas_vendidas INT NOT NULL DEFAULT 0,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_fecha (fecha),
    INDEX idx_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de Tickets/Entradas
CREATE TABLE IF NOT EXISTS tickets (
    id VARCHAR(50) PRIMARY KEY,
    event_id VARCHAR(50) NOT NULL,
    tipo ENUM('GENERAL', 'VIP') NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    asiento VARCHAR(20) NOT NULL,
    seccion VARCHAR(10) NOT NULL,
    disponible BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    INDEX idx_event_id (event_id),
    INDEX idx_tipo (tipo),
    INDEX idx_disponible (disponible),
    INDEX idx_event_tipo_disponible (event_id, tipo, disponible),
    UNIQUE KEY uk_event_asiento (event_id, asiento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de Compras
CREATE TABLE IF NOT EXISTS purchases (
    id VARCHAR(50) PRIMARY KEY,
    event_id VARCHAR(50) NOT NULL,
    nombre_comprador VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL,
    telefono VARCHAR(20),
    cantidad_entradas INT NOT NULL,
    tipo_entrada ENUM('GENERAL', 'VIP') NOT NULL,
    precio_total DECIMAL(10, 2) NOT NULL,
    fecha_compra TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('PENDIENTE', 'CONFIRMADA', 'CANCELADA') NOT NULL DEFAULT 'PENDIENTE',
    codigo_confirmacion VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    INDEX idx_event_id (event_id),
    INDEX idx_email (email),
    INDEX idx_estado (estado),
    INDEX idx_fecha_compra (fecha_compra),
    INDEX idx_codigo_confirmacion (codigo_confirmacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de relación entre Compras y Tickets (asientos asignados)
CREATE TABLE IF NOT EXISTS purchase_tickets (
    purchase_id VARCHAR(50) NOT NULL,
    ticket_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (purchase_id, ticket_id),
    FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    INDEX idx_purchase_id (purchase_id),
    INDEX idx_ticket_id (ticket_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vista para estadísticas de eventos
CREATE OR REPLACE VIEW event_statistics AS
SELECT 
    e.id,
    e.nombre,
    e.fecha,
    e.capacidad_total,
    e.entradas_vendidas,
    (e.capacidad_total - e.entradas_vendidas) AS entradas_disponibles,
    ROUND((e.entradas_vendidas * 100.0 / e.capacidad_total), 2) AS porcentaje_vendido,
    COUNT(DISTINCT p.id) AS total_compras,
    SUM(CASE WHEN t.tipo = 'GENERAL' AND t.disponible = FALSE THEN 1 ELSE 0 END) AS general_vendidas,
    SUM(CASE WHEN t.tipo = 'VIP' AND t.disponible = FALSE THEN 1 ELSE 0 END) AS vip_vendidas,
    SUM(CASE WHEN t.tipo = 'GENERAL' AND t.disponible = TRUE THEN 1 ELSE 0 END) AS general_disponibles,
    SUM(CASE WHEN t.tipo = 'VIP' AND t.disponible = TRUE THEN 1 ELSE 0 END) AS vip_disponibles
FROM events e
LEFT JOIN tickets t ON e.id = t.event_id
LEFT JOIN purchases p ON e.id = p.event_id AND p.estado = 'CONFIRMADA'
GROUP BY e.id, e.nombre, e.fecha, e.capacidad_total, e.entradas_vendidas;

-- Procedimiento almacenado para reservar tickets
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS reservar_tickets(
    IN p_event_id VARCHAR(50),
    IN p_tipo_entrada VARCHAR(10),
    IN p_cantidad INT,
    IN p_nombre_comprador VARCHAR(200),
    IN p_email VARCHAR(200),
    IN p_telefono VARCHAR(20),
    OUT p_purchase_id VARCHAR(50),
    OUT p_success BOOLEAN,
    OUT p_message VARCHAR(500)
)
BEGIN
    DECLARE v_disponibles INT;
    DECLARE v_precio_unitario DECIMAL(10, 2);
    DECLARE v_precio_total DECIMAL(10, 2);
    DECLARE v_codigo_confirmacion VARCHAR(100);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = FALSE;
        SET p_message = 'Error al procesar la compra';
    END;
    
    START TRANSACTION;
    
    -- Verificar disponibilidad
    SELECT COUNT(*) INTO v_disponibles
    FROM tickets
    WHERE event_id = p_event_id 
    AND tipo = p_tipo_entrada 
    AND disponible = TRUE
    FOR UPDATE;
    
    IF v_disponibles < p_cantidad THEN
        SET p_success = FALSE;
        SET p_message = CONCAT('Solo hay ', v_disponibles, ' entradas disponibles del tipo ', p_tipo_entrada);
        ROLLBACK;
    ELSE
        -- Obtener precio
        SET v_precio_unitario = CASE 
            WHEN p_tipo_entrada = 'GENERAL' THEN 150.00
            WHEN p_tipo_entrada = 'VIP' THEN 450.00
            ELSE 0
        END;
        
        SET v_precio_total = v_precio_unitario * p_cantidad;
        
        -- Generar ID de compra
        SET p_purchase_id = CONCAT('PUR-', UNIX_TIMESTAMP(), '-', SUBSTRING(MD5(RAND()), 1, 8));
        SET v_codigo_confirmacion = CONCAT('F1-', UNIX_TIMESTAMP(), '-', SUBSTRING(p_purchase_id, 1, 4));
        
        -- Crear compra
        INSERT INTO purchases (
            id, event_id, nombre_comprador, email, telefono,
            cantidad_entradas, tipo_entrada, precio_total,
            estado, codigo_confirmacion
        ) VALUES (
            p_purchase_id, p_event_id, p_nombre_comprador, p_email, p_telefono,
            p_cantidad, p_tipo_entrada, v_precio_total,
            'CONFIRMADA', v_codigo_confirmacion
        );
        
        -- Reservar tickets y crear relaciones
        INSERT INTO purchase_tickets (purchase_id, ticket_id)
        SELECT p_purchase_id, id
        FROM tickets
        WHERE event_id = p_event_id 
        AND tipo = p_tipo_entrada 
        AND disponible = TRUE
        LIMIT p_cantidad;
        
        -- Marcar tickets como no disponibles
        UPDATE tickets
        SET disponible = FALSE
        WHERE id IN (
            SELECT ticket_id FROM purchase_tickets WHERE purchase_id = p_purchase_id
        );
        
        -- Actualizar contador de entradas vendidas en el evento
        UPDATE events
        SET entradas_vendidas = entradas_vendidas + p_cantidad
        WHERE id = p_event_id;
        
        SET p_success = TRUE;
        SET p_message = CONCAT('Compra realizada exitosamente. Código: ', v_codigo_confirmacion);
        
        COMMIT;
    END IF;
END //

DELIMITER ;

-- Trigger para validar capacidad antes de insertar tickets
DELIMITER //

CREATE TRIGGER IF NOT EXISTS before_ticket_insert
BEFORE INSERT ON tickets
FOR EACH ROW
BEGIN
    DECLARE v_total_tickets INT;
    DECLARE v_capacidad INT;
    
    SELECT COUNT(*) INTO v_total_tickets
    FROM tickets
    WHERE event_id = NEW.event_id;
    
    SELECT capacidad_total INTO v_capacidad
    FROM events
    WHERE id = NEW.event_id;
    
    IF v_total_tickets >= v_capacidad THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se pueden crear más tickets, capacidad del evento alcanzada';
    END IF;
END //

DELIMITER ;

-- Índices adicionales para optimización
CREATE INDEX idx_tickets_event_disponible ON tickets(event_id, disponible);
CREATE INDEX idx_purchases_event_estado ON purchases(event_id, estado);

-- Comentarios en las tablas
ALTER TABLE events COMMENT = 'Tabla de eventos de Fórmula 1';
ALTER TABLE tickets COMMENT = 'Tabla de entradas/tickets disponibles para cada evento';
ALTER TABLE purchases COMMENT = 'Tabla de compras realizadas por los clientes';
ALTER TABLE purchase_tickets COMMENT = 'Relación entre compras y tickets asignados';

-- Made with Bob
