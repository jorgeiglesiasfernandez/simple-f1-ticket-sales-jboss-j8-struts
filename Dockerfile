# =====================================================
# Dockerfile Monolítico - WildFly 26 + MySQL 8.0
# Compatible con arquitectura ARM64 (Apple Silicon)
# WildFly 26 es compatible con JBoss EAP 7.4
# =====================================================

FROM registry.access.redhat.com/ubi8/ubi:8.8

LABEL maintainer="F1 Tickets Team"
LABEL description="Aplicación monolítica F1 Tickets con WildFly 26 y MySQL 8.0"
LABEL version="1.0.0"

# Variables de entorno
ENV WILDFLY_VERSION=26.1.3.Final \
    WILDFLY_HOME=/opt/wildfly \
    MYSQL_ROOT_PASSWORD=rootpass \
    MYSQL_DATABASE=f1_tickets \
    MYSQL_USER=f1user \
    MYSQL_PASSWORD=f1pass \
    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# Deshabilitar repositorios RHEL que requieren suscripción (solo para desarrollo local)
# En CRC/OpenShift estos repositorios están disponibles automáticamente
RUN rm -f /etc/yum.repos.d/redhat.repo && \
    sed -i 's/enabled=1/enabled=0/g' /etc/yum/pluginconf.d/subscription-manager.conf || true

# Instalar dependencias básicas desde repositorios UBI públicos
RUN yum install -y \
    java-1.8.0-openjdk \
    java-1.8.0-openjdk-devel \
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

# Descargar e instalar WildFly primero
RUN cd /opt && \
    wget -q https://github.com/wildfly/wildfly/releases/download/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.tar.gz && \
    tar xzf wildfly-${WILDFLY_VERSION}.tar.gz && \
    mv wildfly-${WILDFLY_VERSION} wildfly && \
    rm wildfly-${WILDFLY_VERSION}.tar.gz

# Crear usuario wildfly después de instalar WildFly
RUN groupadd -r wildfly -g 1000 && \
    useradd -u 1000 -r -g wildfly -s /sbin/nologin -c "WildFly user" wildfly && \
    chown -R wildfly:wildfly /opt/wildfly

# Descargar MySQL Connector/J (usar com/mysql/mysql-connector-j en lugar de mysql/mysql-connector-java)
RUN cd /opt && \
    wget -q https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar && \
    chown wildfly:wildfly mysql-connector-j-8.0.33.jar

# Configurar MySQL
RUN mkdir -p /var/lib/mysql /var/run/mysqld /var/log/mysql && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /var/log/mysql && \
    chmod 755 /var/run/mysqld

# Inicializar base de datos MySQL (MySQL 8.0 se inicializa automáticamente al primer arranque)
RUN mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql

# Copiar configuración de MySQL para consola (sin logs a archivo)
COPY docker-scripts/my-console.cnf /etc/my.cnf.d/console.cnf

# Copiar scripts SQL
COPY database/schema.sql /docker-entrypoint-initdb.d/01-schema.sql
COPY database/initial-data.sql /docker-entrypoint-initdb.d/02-initial-data.sql

# Copiar WAR de la aplicación
COPY target/f1-tickets.war ${WILDFLY_HOME}/standalone/deployments/

# Copiar scripts de configuración
COPY docker-scripts/init-mysql.sh /opt/init-mysql.sh
COPY docker-scripts/configure-wildfly.sh /opt/configure-wildfly.sh
COPY docker-scripts/supervisord.conf /etc/supervisord.conf
COPY docker-scripts/entrypoint.sh /opt/entrypoint.sh

# Copiar scripts de carga de datos y utilidades
COPY docker-scripts/load-purchases-24.sh /opt/load-purchases-24.sh
COPY docker-scripts/load-purchases-128.sh /opt/load-purchases-128.sh
COPY docker-scripts/load-purchases-17.sh /opt/load-purchases-17.sh
COPY docker-scripts/reset-database.sh /opt/reset-database.sh

# Dar permisos de ejecución a los scripts
RUN chmod +x /opt/init-mysql.sh /opt/configure-wildfly.sh /opt/entrypoint.sh \
    /opt/load-purchases-24.sh /opt/load-purchases-128.sh /opt/load-purchases-17.sh \
    /opt/reset-database.sh

# Crear directorios de logs
RUN mkdir -p /var/log/supervisor /var/log/mysql /var/log/wildfly && \
    chown -R wildfly:wildfly /var/log/wildfly && \
    chown -R mysql:mysql /var/log/mysql

# Exponer puertos
# 8080: HTTP WildFly
# 9990: Management Console WildFly
# 3306: MySQL
EXPOSE 8080 9990 3306

# Volúmenes para persistencia
VOLUME ["/var/lib/mysql", "/opt/wildfly/standalone/deployments"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/f1-tickets/ || exit 1

# Comando de inicio
WORKDIR /opt
ENTRYPOINT ["/opt/entrypoint.sh"]

# Made with Bob
