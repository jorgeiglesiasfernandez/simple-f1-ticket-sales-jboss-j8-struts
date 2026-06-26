#!/bin/bash
set -e

echo "=========================================="
echo "Iniciando aplicación monolítica F1 Tickets"
echo "WildFly 26 (JBoss EAP 7.4 compatible) + MySQL 8.0"
echo "=========================================="

# Verificar si es la primera ejecución
if [ ! -f /var/lib/mysql/.initialized ]; then
    echo "Primera ejecución: Inicializando MySQL..."
    /opt/init-mysql.sh
    touch /var/lib/mysql/.initialized
    
    echo "Configurando WildFly..."
    /opt/configure-wildfly.sh
fi

echo "Iniciando servicios con Supervisor..."
exec /usr/local/bin/supervisord -c /etc/supervisord.conf

# Made with Bob
