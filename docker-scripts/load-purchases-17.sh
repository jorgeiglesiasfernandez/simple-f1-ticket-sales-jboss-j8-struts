#!/bin/bash
# Script para cargar 17 compras de prueba usando la API REST
# Uso: ./load-purchases-17.sh

set -e

API_URL="http://localhost:8080/f1-tickets/api/purchases"
TOTAL_PURCHASES=17
SUCCESS_COUNT=0
FAILED_COUNT=0

echo "=========================================="
echo "Cargando 17 compras de prueba"
echo "=========================================="

# Array de nombres ficticios específicos
NOMBRES=(
    "Alejandro Martín" "Beatriz Soto" "Carlos Vázquez" "Diana Campos"
    "Eduardo Prieto" "Fernanda Gil" "Gabriel Méndez" "Helena Cortés"
    "Ignacio Reyes" "Julia Santos" "Kevin Vargas" "Lidia Pascual"
    "Marcos Iglesias" "Nuria Cabrera" "Óscar Fuentes" "Patricia León"
    "Quique Domínguez"
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
    
    # Distribución variada: algunos VIP, mayoría GENERAL
    if [ $i -eq 5 ] || [ $i -eq 11 ] || [ $i -eq 17 ]; then
        TIPO="VIP"
        CANTIDAD=$((RANDOM % 2 + 2))  # 2-3 entradas VIP
    else
        TIPO="GENERAL"
        CANTIDAD=$((RANDOM % 6 + 1))  # 1-6 entradas GENERAL
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
        # Mostrar ID de compra si está disponible
        PURCHASE_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$PURCHASE_ID" ]; then
            echo "  ID de compra: $PURCHASE_ID"
        fi
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        echo "  ✗ Error en compra (HTTP $HTTP_CODE)"
        echo "  Respuesta: $BODY"
    fi
    
    # Pausa entre peticiones
    sleep 0.3
done

echo ""
echo "=========================================="
echo "Resumen de carga"
echo "=========================================="
echo "Total intentos: $TOTAL_PURCHASES"
echo "Exitosas: $SUCCESS_COUNT"
echo "Fallidas: $FAILED_COUNT"
if [ $TOTAL_PURCHASES -gt 0 ]; then
    echo "Tasa de éxito: $((SUCCESS_COUNT * 100 / TOTAL_PURCHASES))%"
fi
echo "=========================================="

# Mostrar estadísticas finales
echo ""
echo "Consultando estadísticas del evento..."
curl -s "http://localhost:8080/f1-tickets/api/events/F1-2026-ESP" | python3 -m json.tool 2>/dev/null || echo "No se pudieron obtener estadísticas"

# Mostrar últimas compras
echo ""
echo "Últimas 5 compras realizadas:"
curl -s "http://localhost:8080/f1-tickets/api/purchases?limit=5" | python3 -m json.tool 2>/dev/null || echo "No se pudieron obtener las compras"

exit 0

# Made with Bob
