#!/bin/bash
# Script para limpiar la base de datos y restaurarla al estado inicial
# Uso: ./reset-database.sh

set -e

echo "=========================================="
echo "Limpieza y Restauración de Base de Datos"
echo "=========================================="
echo ""
echo "⚠️  ADVERTENCIA: Esta operación eliminará TODAS las compras"
echo "    y restaurará la base de datos al estado inicial."
echo ""

# Solicitar confirmación
read -p "¿Está seguro de que desea continuar? (escriba 'SI' para confirmar): " CONFIRMACION

if [ "$CONFIRMACION" != "SI" ]; then
    echo "Operación cancelada."
    exit 0
fi

echo ""
echo "Iniciando limpieza de base de datos..."

# Configuración de MySQL
DB_USER="f1user"
DB_PASS="f1pass"
DB_NAME="f1_tickets"

# Verificar estado actual
echo ""
echo "Estado ANTES de la limpieza:"
echo "----------------------------"
mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME} --default-character-set=utf8mb4 -e "
SELECT 
    'Compras totales' AS Metrica,
    COUNT(*) AS Valor
FROM purchases
UNION ALL
SELECT 
    'Entradas vendidas' AS Metrica,
    SUM(cantidad_entradas) AS Valor
FROM purchases
UNION ALL
SELECT 
    'Tickets disponibles' AS Metrica,
    COUNT(*) AS Valor
FROM tickets
WHERE disponible = TRUE
UNION ALL
SELECT 
    'Tickets vendidos' AS Metrica,
    COUNT(*) AS Valor
FROM tickets
WHERE disponible = FALSE;
" 2>/dev/null

echo ""
echo "Ejecutando limpieza..."

# Ejecutar limpieza de la base de datos
mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME} --default-character-set=utf8mb4 << 'EOSQL'
-- Deshabilitar verificación de claves foráneas temporalmente
SET FOREIGN_KEY_CHECKS = 0;

-- Limpiar tabla de relación purchase_tickets
TRUNCATE TABLE purchase_tickets;

-- Limpiar tabla de compras
TRUNCATE TABLE purchases;

-- Restaurar todos los tickets a disponible
UPDATE tickets SET disponible = TRUE;

-- Resetear contador de entradas vendidas en eventos
UPDATE events SET entradas_vendidas = 0;

-- Habilitar verificación de claves foráneas
SET FOREIGN_KEY_CHECKS = 1;

-- Verificar resultado
SELECT 'Limpieza completada exitosamente' AS Estado;
EOSQL

if [ $? -eq 0 ]; then
    echo "✓ Limpieza ejecutada correctamente"
else
    echo "✗ Error durante la limpieza"
    exit 1
fi

# Verificar estado después de la limpieza
echo ""
echo "Estado DESPUÉS de la limpieza:"
echo "-------------------------------"
mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME} --default-character-set=utf8mb4 -e "
SELECT 
    'Compras totales' AS Metrica,
    COUNT(*) AS Valor
FROM purchases
UNION ALL
SELECT 
    'Entradas vendidas' AS Metrica,
    COALESCE(SUM(cantidad_entradas), 0) AS Valor
FROM purchases
UNION ALL
SELECT 
    'Tickets disponibles' AS Metrica,
    COUNT(*) AS Valor
FROM tickets
WHERE disponible = TRUE
UNION ALL
SELECT 
    'Tickets vendidos' AS Metrica,
    COUNT(*) AS Valor
FROM tickets
WHERE disponible = FALSE;
" 2>/dev/null

# Mostrar información del evento
echo ""
echo "Información del evento restaurado:"
echo "----------------------------------"
mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME} --default-character-set=utf8mb4 -e "
SELECT 
    id AS 'ID Evento',
    nombre AS 'Nombre',
    DATE_FORMAT(fecha, '%d/%m/%Y %H:%i') AS 'Fecha',
    capacidad_total AS 'Capacidad Total',
    entradas_vendidas AS 'Vendidas',
    (capacidad_total - entradas_vendidas) AS 'Disponibles'
FROM events;
" 2>/dev/null

# Mostrar disponibilidad por tipo
echo ""
echo "Disponibilidad por tipo de entrada:"
echo "------------------------------------"
mysql -u${DB_USER} -p${DB_PASS} ${DB_NAME} --default-character-set=utf8mb4 -e "
SELECT 
    tipo AS 'Tipo',
    COUNT(*) AS 'Total',
    SUM(CASE WHEN disponible = TRUE THEN 1 ELSE 0 END) AS 'Disponibles',
    SUM(CASE WHEN disponible = FALSE THEN 1 ELSE 0 END) AS 'Vendidas',
    CONCAT(MIN(precio), ' €') AS 'Precio'
FROM tickets
GROUP BY tipo;
" 2>/dev/null

echo ""
echo "=========================================="
echo "✓ Base de datos restaurada al estado inicial"
echo "=========================================="
echo ""
echo "Puede verificar el estado usando la API:"
echo "  curl http://localhost:8080/f1-tickets/api/events/F1-2026-ESP"
echo "  curl http://localhost:8080/f1-tickets/api/tickets/availability"
echo ""

exit 0

# Made with Bob
