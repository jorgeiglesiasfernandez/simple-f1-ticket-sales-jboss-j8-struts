# Dockerfile para OpenShift - Sistema de Venta de Entradas F1
# Aplicación Monolítica basada en JBoss EAP 7.4

FROM registry.redhat.io/jboss-eap-7/eap74-openjdk8-openshift-rhel8:latest

# Metadata
LABEL name="f1-ticket-sales" \
      version="1.0.0" \
      description="Sistema monolítico de venta de entradas para el Gran Premio de España 2026 - Fórmula 1" \
      maintainer="Made with Bob" \
      architecture="monolithic"

# Variables de entorno para aplicación monolítica
ENV JBOSS_HOME=/opt/eap \
    JAVA_OPTS="-Xms512m -Xmx1024m -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m -Djboss.as.management.blocking.timeout=600" \
    DISABLE_EMBEDDED_JMS_BROKER=true

# Copiar el WAR al directorio de despliegue
COPY --chown=jboss:root target/f1-tickets.war ${JBOSS_HOME}/standalone/deployments/

# Exponer puertos
EXPOSE 8080 8443

# Usuario no-root para OpenShift
USER 185

# Comando de inicio en modo standalone (sin clustering)
CMD ["/opt/eap/bin/openshift-launch.sh"]

# Made with Bob
