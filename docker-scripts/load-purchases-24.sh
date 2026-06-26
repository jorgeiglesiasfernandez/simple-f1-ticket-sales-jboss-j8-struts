#!/bin/bash
# Script para cargar 24 compras de prueba usando la API REST
# Uso: ./load-purchases-24.sh

set -e

API_URL="http://localhost:8080/f1-tickets/api/purchases"
TOTAL_PURCHASES=24
SUCCESS_COUNT=0
FAILED_COUNT=0

echo "=========================================="
echo "Cargando 24 compras de prueba"
echo "=========================================="

# Array de nombres ficticios
NOMBRES=(
    "Carlos García" "María López" "Juan Martínez" "Ana Rodríguez"
    "Pedro Sánchez" "Laura Fernández" "Miguel Torres" "Carmen Ruiz"
    "José Díaz" "Isabel Moreno" "Francisco Jiménez" "Marta Álvarez"
    "Antonio Romero" "Lucía Navarro" "Manuel Serrano" "Elena Blanco"
    "David Molina" "Sara Castro" "Javier Ortiz" "Paula Rubio"
    "Raúl Delgado" "Cristina Vega" "Alberto Ramos" "Beatriz Herrera"
)

# Array de apellidos adicionales para variedad
APELLIDOS=(
    "Pérez" "González" "Ramírez" "Flores" "Rivera"
    "Gómez" "Muñoz" "Rojas" "Medina" "Silva"
)

# Función para generar email
generate_email() {
    local nombre=$1
    local index=$2
    echo "${nombre// /}${index}@example.com" | tr '[:upper:]' '[:lower:]' | iconv -f UTF-8 -t ASCII//TRANSLIT
}

# Función para generar teléfono
generate_phone() {
    echo "+34 6$(printf "%02d" $((RANDOM % 100))) $(printf "%02d" $((RANDOM % 100))) $(printf "%02d" $((RANDOM % 100))) $(printf "%02d" $((RANDOM % 100)))"
}

# Realizar compras
for i in $(seq 1 $TOTAL_PURCHASES); do
    NOMBRE="${NOMBRES[$((i-1))]}"
    EMAIL=$(generate_email "$NOMBRE" $i)
    TELEFONO=$(generate_phone)
    
    # Alternar entre GENERAL y VIP
    if [ $((i % 3)) -eq 0 ]; then
        TIPO="VIP"
        CANTIDAD=$((RANDOM % 3 + 1))  # 1-3 entradas VIP
    else
        TIPO="GENERAL"
        CANTIDAD=$((RANDOM % 5 + 1))  # 1-5 entradas GENERAL
    fi
    
    echo "[$i/$TOTAL_PURCHASES] Comprando $CANTIDAD entrada(s) $TIPO para $NOMBRE..."
    
    # Crear JSON de la compra
    JSON_DATA=$(cat <<EOF
{
    "nombreComprador": "$NOMBRE",
    "email": "$EMAIL",
    "telefono": "$TELEFONO",
    "cantidadEntradas": $CANTIDAD,
    "tipoEntrada": "$TIPO"
}
EOF
)
    
    # Realizar petición POST
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "$JSON_DATA")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 200 ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo "  ✓ Compra exitosa (HTTP $HTTP_CODE)"
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        echo "  ✗ Error en compra (HTTP $HTTP_CODE)"
        echo "  Respuesta: $BODY"
    fi
    
    # Pequeña pausa entre peticiones
    sleep 0.2
done

echo ""
echo "=========================================="
echo "Resumen de carga"
echo "=========================================="
echo "Total intentos: $TOTAL_PURCHASES"
echo "Exitosas: $SUCCESS_COUNT"
echo "Fallidas: $FAILED_COUNT"
echo "=========================================="

# Mostrar estadísticas finales
echo ""
echo "Consultando estadísticas del evento..."
curl -s "http://localhost:8080/f1-tickets/api/events/F1-2026-ESP" | python3 -m json.tool 2>/dev/null || echo "No se pudieron obtener estadísticas"

exit 0

# Made with Bob
