#!/bin/bash
set -e

echo "Iniciando MySQL..."
# Asegurar permisos correctos (solo si se ejecuta como root)
if [ "$(id -u)" = "0" ]; then
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld 2>/dev/null || true
    # Intentar dar permisos a log, pero continuar si falla
    chown -R mysql:mysql /var/log/mysql 2>/dev/null || true
    chmod 755 /var/log/mysql 2>/dev/null || true
    
    # Iniciar MySQL como usuario mysql, con log a stdout si no puede escribir en archivo
    if [ -w /var/log/mysql ]; then
        su -s /bin/bash mysql -c "mysqld --datadir=/var/lib/mysql --log-error=/var/log/mysql/error.log" &
    else
        echo "⚠️  No se puede escribir en /var/log/mysql, usando stdout para logs"
        su -s /bin/bash mysql -c "mysqld --datadir=/var/lib/mysql --log-error-verbosity=2" &
    fi
else
    # Si no es root, iniciar MySQL con log a stdout
    if [ -w /var/log/mysql ]; then
        mysqld --datadir=/var/lib/mysql --log-error=/var/log/mysql/error.log &
    else
        echo "⚠️  No se puede escribir en /var/log/mysql, usando stdout para logs"
        mysqld --datadir=/var/lib/mysql --log-error-verbosity=2 &
    fi
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
