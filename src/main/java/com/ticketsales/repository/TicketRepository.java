package com.ticketsales.repository;

import com.ticketsales.model.Ticket;
import com.ticketsales.model.Ticket.TipoEntrada;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

public class TicketRepository {
    private static TicketRepository instance;
    private final Map<String, Ticket> tickets;
    private int nextTicketNumber = 1;
    
    private TicketRepository() {
        tickets = new ConcurrentHashMap<>();
        initializeTickets();
    }
    
    public static synchronized TicketRepository getInstance() {
        if (instance == null) {
            instance = new TicketRepository();
        }
        return instance;
    }
    
    private void initializeTickets() {
        String eventId = "F1-2026-ESP";
        
        // Crear 700 entradas GENERAL (Secciones A-G, 100 asientos cada una)
        for (char seccion = 'A'; seccion <= 'G'; seccion++) {
            for (int asiento = 1; asiento <= 100; asiento++) {
                String ticketId = "TKT-" + String.format("%04d", nextTicketNumber++);
                String asientoStr = seccion + String.format("%03d", asiento);
                Ticket ticket = new Ticket(ticketId, eventId, TipoEntrada.GENERAL, asientoStr, String.valueOf(seccion));
                tickets.put(ticketId, ticket);
            }
        }
        
        // Crear 300 entradas VIP (Secciones V1-V3, 100 asientos cada una)
        for (int seccionNum = 1; seccionNum <= 3; seccionNum++) {
            String seccion = "V" + seccionNum;
            for (int asiento = 1; asiento <= 100; asiento++) {
                String ticketId = "TKT-" + String.format("%04d", nextTicketNumber++);
                String asientoStr = seccion + String.format("%03d", asiento);
                Ticket ticket = new Ticket(ticketId, eventId, TipoEntrada.VIP, asientoStr, seccion);
                tickets.put(ticketId, ticket);
            }
        }
    }
    
    public List<Ticket> getAvailableTickets() {
        return tickets.values().stream()
            .filter(Ticket::isDisponible)
            .collect(Collectors.toList());
    }
    
    public List<Ticket> getAvailableTicketsByType(TipoEntrada tipo) {
        return tickets.values().stream()
            .filter(Ticket::isDisponible)
            .filter(t -> t.getTipo() == tipo)
            .collect(Collectors.toList());
    }
    
    public long countAvailableByType(TipoEntrada tipo) {
        return tickets.values().stream()
            .filter(Ticket::isDisponible)
            .filter(t -> t.getTipo() == tipo)
            .count();
    }
    
    public synchronized List<Ticket> reserveTickets(TipoEntrada tipo, int cantidad) {
        List<Ticket> available = getAvailableTicketsByType(tipo);
        
        if (available.size() < cantidad) {
            return null; // No hay suficientes entradas disponibles
        }
        
        List<Ticket> reserved = new ArrayList<>();
        for (int i = 0; i < cantidad && i < available.size(); i++) {
            Ticket ticket = available.get(i);
            ticket.reservar();
            reserved.add(ticket);
        }
        
        return reserved;
    }
    
    public synchronized boolean releaseTickets(List<String> ticketIds) {
        for (String ticketId : ticketIds) {
            Ticket ticket = tickets.get(ticketId);
            if (ticket != null) {
                ticket.liberar();
            }
        }
        return true;
    }
    
    public Ticket findById(String id) {
        return tickets.get(id);
    }
    
    public int getRemainingCapacity() {
        return (int) tickets.values().stream()
            .filter(Ticket::isDisponible)
            .count();
    }
    
    public int getTotalCapacity() {
        return tickets.size();
    }
    
    public int getSoldTickets() {
        return (int) tickets.values().stream()
            .filter(t -> !t.isDisponible())
            .count();
    }
    
    public Map<TipoEntrada, Long> getAvailabilityByType() {
        Map<TipoEntrada, Long> availability = new HashMap<>();
        availability.put(TipoEntrada.GENERAL, countAvailableByType(TipoEntrada.GENERAL));
        availability.put(TipoEntrada.VIP, countAvailableByType(TipoEntrada.VIP));
        return availability;
    }
    
    // Método para resetear tickets (útil para pruebas)
    public synchronized void resetTickets() {
        tickets.clear();
        nextTicketNumber = 1;
        initializeTickets();
    }
}

// Made with Bob