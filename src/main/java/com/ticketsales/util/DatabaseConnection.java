package com.ticketsales.util;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Clase utilitaria para gestionar conexiones a la base de datos MySQL.
 * Utiliza el DataSource configurado en JBoss/WildFly mediante JNDI.
 */
public class DatabaseConnection {
    private static final Logger LOGGER = Logger.getLogger(DatabaseConnection.class.getName());
    private static final String JNDI_NAME = "java:jboss/datasources/F1TicketsDS";
    private static DataSource dataSource;
    
    // Inicialización estática del DataSource
    static {
        try {
            Context ctx = new InitialContext();
            dataSource = (DataSource) ctx.lookup(JNDI_NAME);
            LOGGER.info("DataSource inicializado correctamente: " + JNDI_NAME);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error al inicializar DataSource: " + JNDI_NAME, e);
            // En caso de error, intentar configuración alternativa para desarrollo
            initializeFallbackDataSource();
        }
    }
    
    /**
     * Configuración alternativa para desarrollo local sin JNDI
     */
    private static void initializeFallbackDataSource() {
        try {
            // Cargar el driver de MySQL
            Class.forName("com.mysql.cj.jdbc.Driver");
            LOGGER.info("Driver MySQL cargado correctamente");
            
            // Crear un DataSource simple para desarrollo
            org.apache.commons.dbcp2.BasicDataSource bds = new org.apache.commons.dbcp2.BasicDataSource();
            bds.setDriverClassName("com.mysql.cj.jdbc.Driver");
            bds.setUrl(getJdbcUrl());
            bds.setUsername(getDbUsername());
            bds.setPassword(getDbPassword());
            bds.setInitialSize(5);
            bds.setMaxTotal(20);
            bds.setMaxIdle(10);
            bds.setMinIdle(5);
            bds.setMaxWaitMillis(10000);
            bds.setTestOnBorrow(true);
            bds.setTestWhileIdle(true);
            bds.setValidationQuery("SELECT 1");
            
            dataSource = bds;
            LOGGER.info("DataSource alternativo configurado para desarrollo");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error al configurar DataSource alternativo", e);
        }
    }
    
    /**
     * Obtiene una conexión a la base de datos desde el pool de conexiones
     * 
     * @return Connection objeto de conexión a la base de datos
     * @throws SQLException si hay un error al obtener la conexión
     */
    public static Connection getConnection() throws SQLException {
        if (dataSource == null) {
            throw new SQLException("DataSource no está inicializado");
        }
        
        Connection conn = dataSource.getConnection();
        
        if (conn == null) {
            throw new SQLException("No se pudo obtener una conexión del DataSource");
        }
        
        // Configurar la conexión
        conn.setAutoCommit(true);
        
        LOGGER.fine("Conexión obtenida exitosamente");
        return conn;
    }
    
    /**
     * Cierra una conexión de forma segura
     * 
     * @param conn conexión a cerrar
     */
    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                if (!conn.isClosed()) {
                    conn.close();
                    LOGGER.fine("Conexión cerrada exitosamente");
                }
            } catch (SQLException e) {
                LOGGER.log(Level.WARNING, "Error al cerrar la conexión", e);
            }
        }
    }
    
    /**
     * Cierra recursos de base de datos de forma segura
     * 
     * @param conn conexión a cerrar
     * @param stmt statement a cerrar
     * @param rs result set a cerrar
     */
    public static void closeResources(Connection conn, java.sql.Statement stmt, java.sql.ResultSet rs) {
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException e) {
                LOGGER.log(Level.WARNING, "Error al cerrar ResultSet", e);
            }
        }
        
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException e) {
                LOGGER.log(Level.WARNING, "Error al cerrar Statement", e);
            }
        }
        
        closeConnection(conn);
    }
    
    /**
     * Verifica si la conexión a la base de datos está disponible
     * 
     * @return true si la conexión está disponible, false en caso contrario
     */
    public static boolean testConnection() {
        Connection conn = null;
        try {
            conn = getConnection();
            return conn != null && !conn.isClosed();
        } catch (SQLException e) {
            LOGGER.log(Level.WARNING, "Error al probar la conexión", e);
            return false;
        } finally {
            closeConnection(conn);
        }
    }
    
    /**
     * Obtiene la URL JDBC desde variables de entorno o usa valores por defecto
     */
    private static String getJdbcUrl() {
        String host = System.getenv().getOrDefault("DB_HOST", "localhost");
        String port = System.getenv().getOrDefault("DB_PORT", "3306");
        String database = System.getenv().getOrDefault("DB_NAME", "f1_tickets");
        
        return String.format(
            "jdbc:mysql://%s:%s/%s?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true&useUnicode=true&characterEncoding=UTF-8",
            host, port, database
        );
    }
    
    /**
     * Obtiene el usuario de base de datos desde variables de entorno o usa valor por defecto
     */
    private static String getDbUsername() {
        return System.getenv().getOrDefault("DB_USER", "f1user");
    }
    
    /**
     * Obtiene la contraseña de base de datos desde variables de entorno o usa valor por defecto
     */
    private static String getDbPassword() {
        return System.getenv().getOrDefault("DB_PASSWORD", "f1pass");
    }
    
    /**
     * Ejecuta una transacción con manejo automático de commit/rollback
     * 
     * @param transaction la transacción a ejecutar
     * @return true si la transacción fue exitosa, false en caso contrario
     */
    public static boolean executeTransaction(DatabaseTransaction transaction) {
        Connection conn = null;
        try {
            conn = getConnection();
            conn.setAutoCommit(false);
            
            boolean result = transaction.execute(conn);
            
            if (result) {
                conn.commit();
                LOGGER.fine("Transacción completada exitosamente");
            } else {
                conn.rollback();
                LOGGER.warning("Transacción revertida");
            }
            
            return result;
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error en la transacción", e);
            if (conn != null) {
                try {
                    conn.rollback();
                    LOGGER.info("Rollback ejecutado debido a error");
                } catch (SQLException ex) {
                    LOGGER.log(Level.SEVERE, "Error al hacer rollback", ex);
                }
            }
            return false;
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                } catch (SQLException e) {
                    LOGGER.log(Level.WARNING, "Error al restaurar autoCommit", e);
                }
            }
            closeConnection(conn);
        }
    }
    
    /**
     * Interfaz funcional para ejecutar transacciones
     */
    @FunctionalInterface
    public interface DatabaseTransaction {
        boolean execute(Connection conn) throws SQLException;
    }
}

// Made with Bob