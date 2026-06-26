#!/bin/bash
set -e

echo "Iniciando MySQL..."
mysqld --user=mysql --datadir=/var/lib/mysql &
MYSQL_PID=$!

# Esperar a que MySQL esté listo
echo "Esperando a que MySQL esté listo..."
for i in {30..0}; do
    if mysqladmin ping -h localhost --silent; then
        break
    fi
    echo "MySQL no está listo, esperando..."
    sleep 2
done

if [ "$i" = 0 ]; then
    echo "Error: MySQL no se inició correctamente"
    exit 1
fi

echo "MySQL iniciado correctamente"

# Configurar usuario root
mysql -u root << EOSQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

# Ejecutar scripts de inicialización
echo "Ejecutando scripts de inicialización..."
mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} < /docker-entrypoint-initdb.d/01-schema.sql
mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} < /docker-entrypoint-initdb.d/02-initial-data.sql

echo "Base de datos inicializada correctamente"

# Made with Bob
