#!/bin/bash
set -e

echo "Iniciando WildFly en modo standalone para configuración..."
${WILDFLY_HOME}/bin/standalone.sh &
WILDFLY_PID=$!

# Esperar a que WildFly esté listo
echo "Esperando a que WildFly esté listo..."
for i in {60..0}; do
    if ${WILDFLY_HOME}/bin/jboss-cli.sh --connect --command=":read-attribute(name=server-state)" 2>/dev/null | grep -q "running"; then
        break
    fi
    echo "WildFly no está listo, esperando..."
    sleep 2
done

if [ "$i" = 0 ]; then
    echo "Error: WildFly no se inició correctamente"
    kill $WILDFLY_PID 2>/dev/null || true
    exit 1
fi

echo "WildFly iniciado, configurando datasource..."

# Instalar módulo MySQL y configurar datasource
${WILDFLY_HOME}/bin/jboss-cli.sh --connect << EOCLI
module add --name=com.mysql --resources=/opt/mysql-connector-j-8.0.33.jar --dependencies=javax.api,javax.transaction.api

/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)

data-source add --name=F1TicketsDS --jndi-name=java:jboss/datasources/F1TicketsDS --driver-name=mysql --connection-url=jdbc:mysql://localhost:3306/${MYSQL_DATABASE}?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true --user-name=${MYSQL_USER} --password=${MYSQL_PASSWORD} --use-ccm=true --max-pool-size=20 --min-pool-size=5 --enabled=true

/subsystem=datasources/data-source=F1TicketsDS:test-connection-in-pool

:shutdown
EOCLI

wait $WILDFLY_PID
echo "WildFly configurado correctamente"

# Made with Bob
