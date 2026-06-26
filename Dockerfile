# =====================================================
# Dockerfile Monolítico - JBoss EAP 7.4 + MySQL 8.0
# Usa imagen oficial de Red Hat JBoss EAP 7.4
# =====================================================

FROM registry.redhat.io/jboss-eap-7/eap74-openjdk8-openshift-rhel8:latest

USER root

LABEL maintainer="F1 Tickets Team"
LABEL description="Aplicación monolítica F1 Tickets con JBoss EAP 7.4 y MySQL 8.0"
LABEL version="1.0.0"

# Variables de entorno
ENV MYSQL_ROOT_PASSWORD=rootpass \
    MYSQL_DATABASE=f1_tickets \
    MYSQL_USER=f1user \
    MYSQL_PASSWORD=f1pass

# Instalar dependencias básicas
RUN yum install -y \
    wget \
    tar \
    python3-pip \
    procps \
    net-tools \
    && yum clean all

# Instalar supervisor
RUN pip3 install supervisor

# Instalar MySQL 8.0 desde repositorio de Oracle
RUN wget https://dev.mysql.com/get/mysql80-community-release-el8-9.noarch.rpm && \
    rpm -ivh mysql80-community-release-el8-9.noarch.rpm && \
    yum install -y mysql-server mysql && \
    yum clean all && \
    rm -f mysql80-community-release-el8-9.noarch.rpm

# Configurar MySQL
RUN mkdir -p /var/lib/mysql /var/run/mysqld /var/log/mysql && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /var/log/mysql && \
    chmod 755 /var/run/mysqld

# Inicializar base de datos MySQL
RUN mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql

# Descargar MySQL Connector/J
RUN cd /opt && \
    wget -q https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar && \
    chown jboss:root mysql-connector-java-8.0.33.jar

# Copiar scripts SQL
COPY database/schema.sql /docker-entrypoint-initdb.d/01-schema.sql
COPY database/initial-data.sql /docker-entrypoint-initdb.d/02-initial-data.sql

# Copiar WAR de la aplicación
COPY target/f1-tickets.war /deployments/

# Crear script de inicialización de MySQL
RUN cat > /opt/init-mysql.sh << 'EOF'
#!/bin/bash
set -e

echo "Iniciando MySQL..."
mysqld_safe --user=mysql --datadir=/var/lib/mysql &
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
EOF

RUN chmod +x /opt/init-mysql.sh

# Crear script de configuración de JBoss
RUN cat > /opt/configure-jboss.sh << 'EOF'
#!/bin/bash
set -e

echo "Iniciando JBoss EAP en modo standalone para configuración..."
/opt/eap/bin/standalone.sh &
JBOSS_PID=$!

# Esperar a que JBoss esté listo
echo "Esperando a que JBoss EAP esté listo..."
for i in {60..0}; do
    if /opt/eap/bin/jboss-cli.sh --connect --command=":read-attribute(name=server-state)" 2>/dev/null | grep -q "running"; then
        break
    fi
    echo "JBoss EAP no está listo, esperando..."
    sleep 2
done

if [ "$i" = 0 ]; then
    echo "Error: JBoss EAP no se inició correctamente"
    kill $JBOSS_PID 2>/dev/null || true
    exit 1
fi

echo "JBoss EAP iniciado, configurando datasource..."

# Instalar módulo MySQL y configurar datasource
/opt/eap/bin/jboss-cli.sh --connect << EOCLI
module add --name=com.mysql --resources=/opt/mysql-connector-java-8.0.33.jar --dependencies=javax.api,javax.transaction.api

/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)

data-source add --name=F1TicketsDS --jndi-name=java:jboss/datasources/F1TicketsDS --driver-name=mysql --connection-url=jdbc:mysql://localhost:3306/${MYSQL_DATABASE}?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true --user-name=${MYSQL_USER} --password=${MYSQL_PASSWORD} --use-ccm=true --max-pool-size=20 --min-pool-size=5 --enabled=true

/subsystem=datasources/data-source=F1TicketsDS:test-connection-in-pool

:shutdown
EOCLI

wait $JBOSS_PID
echo "JBoss EAP configurado correctamente"
EOF

RUN chmod +x /opt/configure-jboss.sh

# Configurar Supervisor para gestionar múltiples procesos
RUN cat > /etc/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:mysql]
command=/usr/libexec/mysqld --user=mysql --datadir=/var/lib/mysql
autostart=true
autorestart=true
priority=1
stdout_logfile=/var/log/mysql/mysql.log
stderr_logfile=/var/log/mysql/mysql-error.log

[program:jboss]
command=/opt/eap/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0
user=jboss
autostart=true
autorestart=true
priority=10
stdout_logfile=/var/log/jboss/jboss.log
stderr_logfile=/var/log/jboss/jboss-error.log
EOF

# Crear directorios de logs
RUN mkdir -p /var/log/supervisor /var/log/mysql /var/log/jboss && \
    chown -R jboss:root /var/log/jboss && \
    chown -R mysql:mysql /var/log/mysql

# Script de entrada principal
RUN cat > /opt/entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "Iniciando aplicación monolítica F1 Tickets"
echo "JBoss EAP 7.4 + MySQL 8.0"
echo "=========================================="

# Verificar si es la primera ejecución
if [ ! -f /var/lib/mysql/.initialized ]; then
    echo "Primera ejecución: Inicializando MySQL..."
    /opt/init-mysql.sh
    touch /var/lib/mysql/.initialized
    
    echo "Configurando JBoss EAP..."
    /opt/configure-jboss.sh
fi

echo "Iniciando servicios con Supervisor..."
exec /usr/local/bin/supervisord -c /etc/supervisord.conf
EOF

RUN chmod +x /opt/entrypoint.sh

# Exponer puertos
# 8080: HTTP JBoss EAP
# 9990: Management Console JBoss EAP
# 3306: MySQL
EXPOSE 8080 9990 3306

# Volúmenes para persistencia
VOLUME ["/var/lib/mysql", "/deployments"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/f1-tickets/ || exit 1

# Comando de inicio
WORKDIR /opt
ENTRYPOINT ["/opt/entrypoint.sh"]

# Made with Bob
