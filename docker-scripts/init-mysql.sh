#!/bin/bash
set -e

echo "Iniciando MySQL..."

# Verificar y corregir permisos del datadir
echo "Verificando permisos de /var/lib/mysql..."
if [ "$(id -u)" = "0" ]; then
    # Ejecutando como root - asegurar permisos
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld 2>/dev/null || true
    chmod -R 755 /var/lib/mysql 2>/dev/null || true
    chmod -R 755 /var/run/mysqld 2>/dev/null || true
    
    # Iniciar MySQL como usuario mysql usando configuración de consola
    echo "Iniciando MySQL con logs en consola (compatible con OpenShift/CRC)"
    su -s /bin/bash mysql -c "mysqld --defaults-file=/etc/my.cnf.d/console.cnf" &
else
    # No es root - verificar si podemos escribir en datadir
    if [ ! -w /var/lib/mysql ]; then
        echo "ERROR: /var/lib/mysql no tiene permisos de escritura"
        echo "En OpenShift/CRC, asegúrate de que el SecurityContext permite escritura en el volumen"
        echo "Intentando continuar de todos modos..."
    fi
    
    # Iniciar MySQL con configuración de consola
    echo "Iniciando MySQL con logs en consola (compatible con OpenShift/CRC)"
    mysqld --defaults-file=/etc/my.cnf.d/console.cnf &
fi
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

# Ejecutar scripts de inicialización con codificación UTF-8
echo "Ejecutando scripts de inicialización..."
mysql -u root -p${MYSQL_ROOT_PASSWORD} --default-character-set=utf8mb4 ${MYSQL_DATABASE} < /docker-entrypoint-initdb.d/01-schema.sql
mysql -u root -p${MYSQL_ROOT_PASSWORD} --default-character-set=utf8mb4 ${MYSQL_DATABASE} < /docker-entrypoint-initdb.d/02-initial-data.sql

echo "Base de datos inicializada correctamente"

# Made with Bob
