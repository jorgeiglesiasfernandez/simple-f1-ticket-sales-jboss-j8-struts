package com.ticketsales.repository;

import com.ticketsales.model.Event;
import java.util.Calendar;

public class EventRepository {
    private static EventRepository instance;
    private Event currentEvent;
    
    private EventRepository() {
        initializeEvent();
    }
    
    public static synchronized EventRepository getInstance() {
        if (instance == null) {
            instance = new EventRepository();
        }
        return instance;
    }
    
    private void initializeEvent() {
        // Crear el evento de Fórmula 1
        Calendar cal = Calendar.getInstance();
        cal.set(2026, Calendar.SEPTEMBER, 15, 14, 0, 0); // 15 de Septiembre 2026, 14:00
        
        currentEvent = new Event(
            "F1-2026-ESP",
            "Gran Premio de España 2026",
            cal.getTime(),
            "Circuit de Barcelona-Catalunya",
            "Montmeló, Barcelona, España",
            "Disfruta de la emoción de la Fórmula 1 en el emblemático circuito de Catalunya. " +
            "Vive la velocidad, la adrenalina y el espectáculo del automovilismo de élite."
        );
    }
    
    public Event getEvent() {
        return currentEvent;
    }
    
    public synchronized boolean updateSoldTickets(int cantidad) {
        if (currentEvent.hayDisponibilidad(cantidad)) {
            return currentEvent.venderEntradas(cantidad);
        }
        return false;
    }
    
    public boolean checkCapacity(int cantidad) {
        return currentEvent.hayDisponibilidad(cantidad);
    }
    
    public int getRemainingCapacity() {
        return currentEvent.getEntradasDisponibles();
    }
    
    public int getTotalSold() {
        return currentEvent.getEntradasVendidas();
    }
    
    public double getPercentageSold() {
        return currentEvent.getPorcentajeVendido();
    }
    
    public boolean isSoldOut() {
        return currentEvent.getEntradasDisponibles() == 0;
    }
    
    // Método para resetear el evento (útil para pruebas)
    public synchronized void resetEvent() {
        initializeEvent();
    }
}

// Made with Bob