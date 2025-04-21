
import Foundation

// Protocolo para los elementos que pueden ser repasados con SRS
protocol FlashCardItem: Identifiable {
    var id: String { get }
    var difficultyLevel: Int { get }  // 1-5, donde 5 es el más difícil
    var lastReviewDate: Date? { get set }
    var nextReviewDate: Date? { get set }
    var reviewCount: Int { get set }
    var easeFactor: Double { get set }  // Factor de facilidad (2.5 por defecto)
    var interval: Int { get set }  // Intervalo en días
}

// Extensión del modelo AnatomicalStructure para soportar SRS
extension AnatomicalStructure: FlashCardItem {
    var difficultyLevel: Int {
        return self.difficulty
    }
}

class SpacedRepetitionEngine {
    static let shared = SpacedRepetitionEngine()
    
    // Constantes para el algoritmo SM-2 (SuperMemo-2)
    private let minEaseFactor: Double = 1.3
    private let initialEaseFactor: Double = 2.5
    
    private init() {}
    
    // Calcula la próxima fecha de repaso basada en la respuesta del usuario
    func processReview(for item: inout FlashCardItem, quality: Int) {
        // quality: 0-5, donde 5 es perfecta, 0 es completo olvido
        
        // Inicializar valores si es el primer repaso
        if item.easeFactor == 0 {
            item.easeFactor = initialEaseFactor
        }
        
        if item.interval == 0 {
            item.interval = 1
        }
        
        // Calcular nuevo factor de facilidad
        let newEaseFactor = calculateNewEaseFactor(currentEaseFactor: item.easeFactor, quality: quality)
        item.easeFactor = max(minEaseFactor, newEaseFactor)
        
        // Calcular nuevo intervalo
        if quality < 3 {
            // Si la respuesta no fue buena, resetear intervalo
            item.interval = 1
        } else {
            // Si es la primera vez o se resetea
            if item.reviewCount == 0 || item.interval == 1 {
                item.interval = 1
            } else if item.reviewCount == 1 {
                item.interval = 6
            } else {
                item.interval = Int(Double(item.interval) * item.easeFactor)
            }
        }
        
        // Actualizar contador de repaso y fechas
        item.reviewCount += 1
        item.lastReviewDate = Date()
        item.nextReviewDate = Calendar.current.date(byAdding: .day, value: item.interval, to: Date())
    }
    
    // Calcula el nuevo factor de facilidad basado en la calidad de la respuesta
    private func calculateNewEaseFactor(currentEaseFactor: Double, quality: Int) -> Double {
        let q = Double(max(0, min(5, quality)))
        return currentEaseFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    }
    
    // Obtiene los elementos que necesitan ser repasados hoy
    func getDueItems<T: FlashCardItem>(from items: [T]) -> [T] {
        let today = Date()
        return items.filter { item in
            guard let nextReviewDate = item.nextReviewDate else {
                // Si nunca ha sido repasado, incluirlo
                return true
            }
            
            // Incluir si la fecha de repaso es hoy o anterior
            return nextReviewDate <= today
        }
    }
}
