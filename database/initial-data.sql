-- =====================================================
-- Datos iniciales para F1 Tickets - MySQL 8.0
-- Base de datos: f1_tickets
-- =====================================================

USE f1_tickets;

-- Limpiar datos existentes (solo para desarrollo/testing)
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE purchase_tickets;
TRUNCATE TABLE purchases;
TRUNCATE TABLE tickets;
TRUNCATE TABLE events;
SET FOREIGN_KEY_CHECKS = 1;

-- Insertar evento principal: Gran Premio de España 2026
INSERT INTO events (id, nombre, fecha, circuito, ubicacion, capacidad_total, entradas_vendidas, descripcion)
VALUES (
    'F1-2026-ESP',
    'Gran Premio de España 2026',
    '2026-09-15 14:00:00',
    'Circuit de Barcelona-Catalunya',
    'Montmeló, Barcelona, España',
    1000,
    0,
    'Disfruta de la emoción de la Fórmula 1 en el emblemático circuito de Catalunya. Vive la velocidad, la adrenalina y el espectáculo del automovilismo de élite.'
);

-- Insertar entradas GENERAL (700 entradas)
-- Secciones A-G, 100 asientos cada una

-- Sección A
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n, 4, '0')),
    'F1-2026-ESP',
    'GENERAL',
    150.00,
    CONCAT('A', LPAD(n, 3, '0')),
    'A',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Sección B
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n + 100, 4, '0')),
    'F1-2026-ESP',
    'GENERAL',
    150.00,
    CONCAT('B', LPAD(n, 3, '0')),
    'B',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Sección C
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n + 200, 4, '0')),
    'F1-2026-ESP',
    'GENERAL',
    150.00,
    CONCAT('C', LPAD(n, 3, '0')),
    'C',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Sección D
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n + 300, 4, '0')),
    'F1-2026-ESP',
    'GENERAL',
    150.00,
    CONCAT('D', LPAD(n, 3, '0')),
    'D',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Sección E
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n + 400, 4, '0')),
    'F1-2026-ESP',
    'GENERAL',
    150.00,
    CONCAT('E', LPAD(n, 3, '0')),
    'E',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Sección F
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n + 500, 4, '0')),
    'F1-2026-ESP',
    'GENERAL',
    150.00,
    CONCAT('F', LPAD(n, 3, '0')),
    'F',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Sección G
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n + 600, 4, '0')),
    'F1-2026-ESP',
    'GENERAL',
    150.00,
    CONCAT('G', LPAD(n, 3, '0')),
    'G',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Insertar entradas VIP (300 entradas)
-- Secciones V1-V3, 100 asientos cada una

-- Sección V1
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n + 700, 4, '0')),
    'F1-2026-ESP',
    'VIP',
    450.00,
    CONCAT('V1', LPAD(n, 3, '0')),
    'V1',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Sección V2
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n + 800, 4, '0')),
    'F1-2026-ESP',
    'VIP',
    450.00,
    CONCAT('V2', LPAD(n, 3, '0')),
    'V2',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Sección V3
INSERT INTO tickets (id, event_id, tipo, precio, asiento, seccion, disponible)
SELECT 
    CONCAT('TKT-', LPAD(n + 900, 4, '0')),
    'F1-2026-ESP',
    'VIP',
    450.00,
    CONCAT('V3', LPAD(n, 3, '0')),
    'V3',
    TRUE
FROM (
    SELECT @row := @row + 1 AS n
    FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t1,
         (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) t2,
         (SELECT @row := 0) r
    LIMIT 100
) numbers;

-- Verificar datos insertados
SELECT 
    'Eventos' AS tabla,
    COUNT(*) AS total
FROM events
UNION ALL
SELECT 
    'Tickets GENERAL' AS tabla,
    COUNT(*) AS total
FROM tickets
WHERE tipo = 'GENERAL'
UNION ALL
SELECT 
    'Tickets VIP' AS tabla,
    COUNT(*) AS total
FROM tickets
WHERE tipo = 'VIP'
UNION ALL
SELECT 
    'Total Tickets' AS tabla,
    COUNT(*) AS total
FROM tickets;

-- Mostrar resumen del evento
SELECT 
    id,
    nombre,
    fecha,
    circuito,
    ubicacion,
    capacidad_total,
    entradas_vendidas,
    (capacidad_total - entradas_vendidas) AS disponibles
FROM events;

-- Mostrar disponibilidad por tipo
SELECT 
    tipo,
    COUNT(*) AS total,
    SUM(CASE WHEN disponible = TRUE THEN 1 ELSE 0 END) AS disponibles,
    SUM(CASE WHEN disponible = FALSE THEN 1 ELSE 0 END) AS vendidas,
    MIN(precio) AS precio_min,
    MAX(precio) AS precio_max
FROM tickets
GROUP BY tipo;

-- Made with Bob
