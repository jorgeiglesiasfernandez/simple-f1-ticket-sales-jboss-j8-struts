#!/bin/bash
# Script para cargar 128 compras de prueba usando la API REST
# Uso: ./load-purchases-128.sh

set -e

API_URL="http://localhost:8080/f1-tickets/api/purchases"
TOTAL_PURCHASES=128
SUCCESS_COUNT=0
FAILED_COUNT=0

echo "=========================================="
echo "Cargando 128 compras de prueba"
echo "=========================================="

# Arrays extendidos de nombres y apellidos
NOMBRES=(
    "Carlos" "María" "Juan" "Ana" "Pedro" "Laura" "Miguel" "Carmen"
    "José" "Isabel" "Francisco" "Marta" "Antonio" "Lucía" "Manuel" "Elena"
    "David" "Sara" "Javier" "Paula" "Raúl" "Cristina" "Alberto" "Beatriz"
    "Fernando" "Sofía" "Roberto" "Natalia" "Sergio" "Andrea" "Daniel" "Claudia"
)

APELLIDOS=(
    "García" "López" "Martínez" "Rodríguez" "Sánchez" "Fernández" "Torres" "Ruiz"
    "Díaz" "Moreno" "Jiménez" "Álvarez" "Romero" "Navarro" "Serrano" "Blanco"
    "Molina" "Castro" "Ortiz" "Rubio" "Delgado" "Vega" "Ramos" "Herrera"
    "Pérez" "González" "Ramírez" "Flores" "Rivera" "Gómez" "Muñoz" "Rojas"
)

# Función para generar nombre completo aleatorio
generate_name() {
    local index=$1
    local nombre_idx=$((index % ${#NOMBRES[@]}))
    local apellido1_idx=$(((index * 7) % ${#APELLIDOS[@]}))
    local apellido2_idx=$(((index * 13) % ${#APELLIDOS[@]}))
    echo "${NOMBRES[$nombre_idx]} ${APELLIDOS[$apellido1_idx]} ${APELLIDOS[$apellido2_idx]}"
}

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
    NOMBRE=$(generate_name $i)
    EMAIL=$(generate_email "$NOMBRE" $i)
    TELEFONO=$(generate_phone)
    
    # Distribución: 70% GENERAL, 30% VIP
    if [ $((i % 10)) -lt 7 ]; then
        TIPO="GENERAL"
        CANTIDAD=$((RANDOM % 4 + 1))  # 1-4 entradas GENERAL
    else
        TIPO="VIP"
        CANTIDAD=$((RANDOM % 3 + 1))  # 1-3 entradas VIP
    fi
    
    # Mostrar progreso cada 10 compras
    if [ $((i % 10)) -eq 0 ]; then
        echo "[$i/$TOTAL_PURCHASES] Progreso: $((i * 100 / TOTAL_PURCHASES))% - Exitosas: $SUCCESS_COUNT, Fallidas: $FAILED_COUNT"
    fi
    
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
    
    if [ "$HTTP_CODE" -eq 201 ] || [ "$HTTP_CODE" -eq 200 ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        if [ $((FAILED_COUNT % 5)) -eq 1 ]; then
            BODY=$(echo "$RESPONSE" | sed '$d')
            echo "  ✗ Error en compra #$i (HTTP $HTTP_CODE): $BODY"
        fi
    fi
    
    # Pausa más corta para procesar más rápido
    sleep 0.1
done

echo ""
echo "=========================================="
echo "Resumen de carga"
echo "=========================================="
echo "Total intentos: $TOTAL_PURCHASES"
echo "Exitosas: $SUCCESS_COUNT"
echo "Fallidas: $FAILED_COUNT"
echo "Tasa de éxito: $((SUCCESS_COUNT * 100 / TOTAL_PURCHASES))%"
echo "=========================================="

# Mostrar estadísticas finales
echo ""
echo "Consultando estadísticas del evento..."
curl -s "http://localhost:8080/f1-tickets/api/events/F1-2026-ESP" | python3 -m json.tool 2>/dev/null || echo "No se pudieron obtener estadísticas"

exit 0

# Made with Bob
