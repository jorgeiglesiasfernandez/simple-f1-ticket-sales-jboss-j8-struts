# =====================================================
# Dockerfile Monolítico - JBoss EAP 7.4 + MySQL 8.0
# Simula aplicación legacy en RHEL8
# =====================================================

FROM registry.access.redhat.com/ubi8/ubi:8.8

LABEL maintainer="F1 Tickets Team"
LABEL description="Aplicación monolítica F1 Tickets con JBoss EAP 7.4 y MySQL 8.0 en RHEL8"
LABEL version="1.0.0"

# Variables de entorno
ENV JBOSS_HOME=/opt/jboss/wildfly \
    MYSQL_ROOT_PASSWORD=rootpass \
    MYSQL_DATABASE=f1_tickets \
    MYSQL_USER=f1user \
    MYSQL_PASSWORD=f1pass \
    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# Instalar dependencias del sistema
RUN yum install -y \
    java-1.8.0-openjdk \
    java-1.8.0-openjdk-devel \
    wget \
    unzip \
    mysql-server \
    mysql \
    supervisor \
    procps \
    net-tools \
    && yum clean all

# Crear usuario jboss
RUN groupadd -r jboss -g 1000 && \
    useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss

# Descargar e instalar WildFly (compatible con JBoss EAP 7.4)
RUN cd /opt/jboss && \
    wget -q https://github.com/wildfly/wildfly/releases/download/26.1.3.Final/wildfly-26.1.3.Final.tar.gz && \
    tar xzf wildfly-26.1.3.Final.tar.gz && \
    mv wildfly-26.1.3.Final wildfly && \
    rm wildfly-26.1.3.Final.tar.gz && \
    chown -R jboss:jboss /opt/jboss/wildfly

# Descargar MySQL Connector/J
RUN cd /opt/jboss && \
    wget -q https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar && \
    chown jboss:jboss mysql-connector-java-8.0.33.jar

# Configurar MySQL
RUN mkdir -p /var/lib/mysql /var/run/mysqld /var/log/mysql && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /var/log/mysql && \
    chmod 755 /var/run/mysqld

# Inicializar base de datos MySQL
RUN mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql

# Copiar scripts SQL
COPY database/schema.sql /docker-entrypoint-initdb.d/01-schema.sql
COPY database/initial-data.sql /docker-entrypoint-initdb.d/02-initial-data.sql

# Copiar configuración de JBoss
COPY jboss-config/configure-jboss.cli /opt/jboss/configure-jboss.cli

# Copiar WAR de la aplicación
COPY target/f1-tickets.war /opt/jboss/wildfly/standalone/deployments/

# Crear script de inicialización de MySQL
RUN cat > /opt/jboss/init-mysql.sh << 'EOF'
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
mysql -u root -p${MYSQL_ROOT_PASSWORD} < /docker-entrypoint-initdb.d/01-schema.sql
mysql -u root -p${MYSQL_ROOT_PASSWORD} < /docker-entrypoint-initdb.d/02-initial-data.sql

echo "Base de datos inicializada correctamente"
EOF

RUN chmod +x /opt/jboss/init-mysql.sh

# Crear script de configuración de JBoss
RUN cat > /opt/jboss/configure-jboss.sh << 'EOF'
#!/bin/bash
set -e

echo "Iniciando JBoss en modo standalone para configuración..."
$JBOSS_HOME/bin/standalone.sh &
JBOSS_PID=$!

# Esperar a que JBoss esté listo
echo "Esperando a que JBoss esté listo..."
for i in {60..0}; do
    if $JBOSS_HOME/bin/jboss-cli.sh --connect --command=":read-attribute(name=server-state)" 2>/dev/null | grep -q "running"; then
        break
    fi
    echo "JBoss no está listo, esperando..."
    sleep 2
done

if [ "$i" = 0 ]; then
    echo "Error: JBoss no se inició correctamente"
    kill $JBOSS_PID 2>/dev/null || true
    exit 1
fi

echo "JBoss iniciado, configurando datasource..."

# Instalar módulo MySQL
$JBOSS_HOME/bin/jboss-cli.sh --connect << EOCLI
module add --name=com.mysql --resources=/opt/jboss/mysql-connector-java-8.0.33.jar --dependencies=javax.api,javax.transaction.api

/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)

data-source add --name=F1TicketsDS --jndi-name=java:jboss/datasources/F1TicketsDS --driver-name=mysql --connection-url=jdbc:mysql://localhost:3306/${MYSQL_DATABASE}?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true --user-name=${MYSQL_USER} --password=${MYSQL_PASSWORD} --use-ccm=true --max-pool-size=20 --min-pool-size=5 --enabled=true

/subsystem=datasources/data-source=F1TicketsDS:test-connection-in-pool

:shutdown
EOCLI

wait $JBOSS_PID
echo "JBoss configurado correctamente"
EOF

RUN chmod +x /opt/jboss/configure-jboss.sh

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
command=/opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0
user=jboss
autostart=true
autorestart=true
priority=10
stdout_logfile=/var/log/jboss/jboss.log
stderr_logfile=/var/log/jboss/jboss-error.log
environment=JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"
EOF

# Crear directorios de logs
RUN mkdir -p /var/log/supervisor /var/log/mysql /var/log/jboss && \
    chown -R jboss:jboss /var/log/jboss

# Script de entrada principal
RUN cat > /opt/jboss/entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "Iniciando aplicación monolítica F1 Tickets"
echo "JBoss EAP 7.4 + MySQL 8.0 en RHEL8"
echo "=========================================="

# Verificar si es la primera ejecución
if [ ! -f /var/lib/mysql/.initialized ]; then
    echo "Primera ejecución: Inicializando MySQL..."
    /opt/jboss/init-mysql.sh
    touch /var/lib/mysql/.initialized
    
    echo "Configurando JBoss..."
    /opt/jboss/configure-jboss.sh
fi

echo "Iniciando servicios con Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
EOF

RUN chmod +x /opt/jboss/entrypoint.sh

# Exponer puertos
# 8080: HTTP JBoss
# 9990: Management Console JBoss
# 3306: MySQL
EXPOSE 8080 9990 3306

# Volúmenes para persistencia
VOLUME ["/var/lib/mysql", "/opt/jboss/wildfly/standalone/deployments"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/f1-tickets/ || exit 1

# Usuario y comando de inicio
WORKDIR /opt/jboss
ENTRYPOINT ["/opt/jboss/entrypoint.sh"]

# Made with Bob
