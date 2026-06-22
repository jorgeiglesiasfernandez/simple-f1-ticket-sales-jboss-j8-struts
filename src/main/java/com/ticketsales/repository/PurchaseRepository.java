package com.ticketsales.repository;

import com.ticketsales.model.Purchase;
import java.math.BigDecimal;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

public class PurchaseRepository {
    private static PurchaseRepository instance;
    private final Map<String, Purchase> purchases;
    private final AtomicInteger nextPurchaseId;
    
    private PurchaseRepository() {
        purchases = new ConcurrentHashMap<>();
        nextPurchaseId = new AtomicInteger(1);
    }
    
    public static synchronized PurchaseRepository getInstance() {
        if (instance == null) {
            instance = new PurchaseRepository();
        }
        return instance;
    }
    
    public synchronized Purchase createPurchase(Purchase purchase) {
        if (purchase.getId() == null || purchase.getId().isEmpty()) {
            purchase.setId("PUR-" + String.format("%06d", nextPurchaseId.getAndIncrement()));
        }
        
        purchase.calcularPrecioTotal();
        purchase.setFechaCompra(new Date());
        purchases.put(purchase.getId(), purchase);
        
        return purchase;
    }
    
    public Purchase findById(String id) {
        return purchases.get(id);
    }
    
    public List<Purchase> findAll() {
        return new ArrayList<>(purchases.values());
    }
    
    public List<Purchase> findByEmail(String email) {
        return purchases.values().stream()
            .filter(p -> p.getEmail().equalsIgnoreCase(email))
            .collect(Collectors.toList());
    }
    
    public List<Purchase> findByEstado(String estado) {
        return purchases.values().stream()
            .filter(p -> p.getEstado().equals(estado))
            .collect(Collectors.toList());
    }
    
    public List<Purchase> getRecentPurchases(int limit) {
        return purchases.values().stream()
            .sorted((p1, p2) -> p2.getFechaCompra().compareTo(p1.getFechaCompra()))
            .limit(limit)
            .collect(Collectors.toList());
    }
    
    public void updatePurchase(Purchase purchase) {
        purchases.put(purchase.getId(), purchase);
    }
    
    public boolean deletePurchase(String id) {
        return purchases.remove(id) != null;
    }
    
    // Estadísticas
    public int getTotalPurchases() {
        return purchases.size();
    }
    
    public int getTotalTicketsSold() {
        return purchases.values().stream()
            .filter(p -> "CONFIRMADA".equals(p.getEstado()))
            .mapToInt(Purchase::getCantidadEntradas)
            .sum();
    }
    
    public BigDecimal getTotalRevenue() {
        return purchases.values().stream()
            .filter(p -> "CONFIRMADA".equals(p.getEstado()))
            .map(Purchase::getPrecioTotal)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
    
    public Map<String, Integer> getSalesByType() {
        Map<String, Integer> salesByType = new HashMap<>();
        
        purchases.values().stream()
            .filter(p -> "CONFIRMADA".equals(p.getEstado()))
            .forEach(p -> {
                String tipo = p.getTipoEntrada().name();
                salesByType.put(tipo, salesByType.getOrDefault(tipo, 0) + p.getCantidadEntradas());
            });
        
        return salesByType;
    }
    
    public double getAverageTicketsPerPurchase() {
        List<Purchase> confirmedPurchases = purchases.values().stream()
            .filter(p -> "CONFIRMADA".equals(p.getEstado()))
            .collect(Collectors.toList());
        
        if (confirmedPurchases.isEmpty()) {
            return 0.0;
        }
        
        int totalTickets = confirmedPurchases.stream()
            .mapToInt(Purchase::getCantidadEntradas)
            .sum();
        
        return (double) totalTickets / confirmedPurchases.size();
    }
    
    // Método para resetear compras (útil para pruebas)
    public synchronized void resetPurchases() {
        purchases.clear();
        nextPurchaseId.set(1);
    }
}

// Made with Bob