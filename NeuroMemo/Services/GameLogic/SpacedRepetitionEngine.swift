import Foundation

protocol FlashCardItem {
    var id: String { get }
    var easinessFactor: Double { get set }
    var interval: Int { get set }  // En días
    var learningState: SpacedRepetitionEngine.LearningState { get set }
    var lastReviewDate: Date? { get set }
    var dueDate: Date? { get }
}

class SpacedRepetitionEngine {
    static let shared = SpacedRepetitionEngine()
    
    enum LearningState: String, Codable {
        case new
        case learning
        case review
        case mastered
    }
    
    enum ResponseQuality: Int {
        case completeBlackout = 0
        case incorrect = 1
        case barelyCorrect = 2
        case difficult = 3
        case clear = 4
        case perfect = 5
    }
    
    private let minimumEasinessFactor: Double = 1.3
    
    private init() {}
    
    // Algoritmo SM-2 para calcular el próximo intervalo
    func processResponse<T: FlashCardItem>(for item: T, quality: ResponseQuality) -> T {
        var mutableItem = item
        
        // Actualizar factor de facilidad según la respuesta
        mutableItem.easinessFactor = max(
            minimumEasinessFactor,
            item.easinessFactor + (0.1 - (5 - Double(quality.rawValue)) * (0.08 + (5 - Double(quality.rawValue)) * 0.02))
        )
        
        // Actualizar estado de aprendizaje y calcular próximo intervalo
        switch quality {
        case .completeBlackout, .incorrect:
            // Respuesta incorrecta, volver a estado de aprendizaje
            mutableItem.learningState = .learning
            mutableItem.interval = 1
            
        case .barelyCorrect:
            if mutableItem.learningState == .new {
                mutableItem.learningState = .learning
                mutableItem.interval = 1
            } else {
                // Reducir el intervalo pero mantener el estado
                mutableItem.interval = max(1, Int(Double(mutableItem.interval) * 0.7))
            }
            
        case .difficult, .clear, .perfect:
            // Calcular próximo intervalo según SM-2
            switch mutableItem.learningState {
            case .new:
                mutableItem.learningState = .learning
                mutableItem.interval = 1
                
            case .learning:
                mutableItem.learningState = .review
                mutableItem.interval = 6  // Aproximadamente una semana
                
            case .review:
                // Aumentar el intervalo según factor de facilidad
                mutableItem.interval = Int(Double(mutableItem.interval) * mutableItem.easinessFactor)
                
                // Si el intervalo es mayor a 60 días y la respuesta fue perfecta, marcar como dominado
                if mutableItem.interval > 60 && quality == .perfect {
                    mutableItem.learningState = .mastered
                }
                
            case .mastered:
                // Mantener el estado dominado pero aumentar el intervalo
                mutableItem.interval = Int(Double(mutableItem.interval) * mutableItem.easinessFactor)
            }
        }
        
        // Actualizar fecha de revisión
        mutableItem.lastReviewDate = Date()
        
        // Guardar el estado actualizado
        saveItemState(mutableItem)
        
        return mutableItem
    }
    
    // Determina si un ítem debe ser revisado hoy
    func isDueForReview<T: FlashCardItem>(_ item: T) -> Bool {
        guard let dueDate = item.dueDate else {
            return item.learningState == .new  // Ítems nuevos siempre están listos para revisar
        }
        
        return dueDate <= Date()
    }
    
    // Obtener lista de ítems listos para revisar
    func getDueItems<T: FlashCardItem>(from items: [T]) -> [T] {
        return items.filter { isDueForReview($0) }
    }
    
    // Guardar el estado de un ítem (integración con UserDataManager)
    private func saveItemState<T: FlashCardItem>(_ item: T) {
        if let flashcardItem = item as? FlashCardAnatomicalItem {
            UserDataManager.shared.updateStructureConfidence(
                structureId: flashcardItem.structureId,
                confidenceFactor: flashcardItem.easinessFactor,
                learningState: flashcardItem.learningState
            )
        }
    }
}

// Implementación concreta de FlashCardItem para estructuras anatómicas
class FlashCardAnatomicalItem: FlashCardItem {
    let structureId: String
    let id: String
    var easinessFactor: Double
    var interval: Int
    var learningState: SpacedRepetitionEngine.LearningState
    var lastReviewDate: Date?
    
    var dueDate: Date? {
        guard let lastReview = lastReviewDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: interval, to: lastReview)
    }
    
    init(structureId: String, id: String, easinessFactor: Double = 2.5, interval: Int = 0, 
         learningState: SpacedRepetitionEngine.LearningState = .new, lastReviewDate: Date? = nil) {
        self.structureId = structureId
        self.id = id
        self.easinessFactor = easinessFactor
        self.interval = interval
        self.learningState = learningState
        self.lastReviewDate = lastReviewDate
    }
    
    // Factory para crear desde un AnatomicalStructure y UserProgress
    static func fromAnatomicalStructure(_ structure: AnatomicalStructure, userProgress: UserProgress) -> FlashCardAnatomicalItem {
        // Buscar si hay progreso para esta estructura
        if let studiedStructure = userProgress.studiedStructures.first(where: { $0.structureId == structure.id }) {
            // Convertir confidenceLevel a los parámetros SRS
            let easinessFactor = 2.5 + (Double(studiedStructure.confidenceLevel) - 3) * 0.1
            let learningState: SpacedRepetitionEngine.LearningState
            
            switch studiedStructure.confidenceLevel {
            case 0...1:
                learningState = .new
            case 2...3:
                learningState = .learning
            case 4...6:
                learningState = .review
            default:
                learningState = .mastered
            }
            
            // Calcular intervalo basado en la fecha de última revisión
            let daysSinceLastReview = Calendar.current.dateComponents([.day], 
                                                                       from: studiedStructure.lastReviewDate, 
                                                                       to: Date()).day ?? 0
            let interval = max(1, daysSinceLastReview + studiedStructure.confidenceLevel)
            
            return FlashCardAnatomicalItem(
                structureId: structure.id,
                id: structure.id,
                easinessFactor: easinessFactor,
                interval: interval,
                learningState: learningState,
                lastReviewDate: studiedStructure.lastReviewDate
            )
        } else {
            // Si no hay progreso, crear como nuevo
            return FlashCardAnatomicalItem(
                structureId: structure.id,
                id: structure.id
            )
        }
    }
}

// Extensión a UserDataManager para guardar el estado de FlashCard
extension UserDataManager {
    func updateStructureConfidence(structureId: String, confidenceFactor: Double, learningState: SpacedRepetitionEngine.LearningState) {
        // Convertir parámetros SRS a confidenceLevel
        let confidenceLevel: Int
        
        switch learningState {
        case .new:
            confidenceLevel = 1
        case .learning:
            confidenceLevel = 3
        case .review:
            confidenceLevel = 5
        case .mastered:
            confidenceLevel = 7
        }
        
        // Actualizar la confianza para esta estructura
        updateStructureConfidence(structureId: structureId, newLevel: confidenceLevel)
    }
    
    // Método auxiliar para actualizar el nivel de confianza
    func updateStructureConfidence(structureId: String, newLevel: Int) {
        if let index = currentUser.studiedStructures.firstIndex(where: { $0.structureId == structureId }) {
            currentUser.studiedStructures[index].confidenceLevel = newLevel
            currentUser.studiedStructures[index].lastReviewDate = Date()
        } else {
            // Crear nueva entrada si no existe
            let newStructure = StudiedStructure(
                structureId: structureId,
                timeStudied: 0,
                lastReviewDate: Date(),
                confidenceLevel: newLevel
            )
            currentUser.studiedStructures.append(newStructure)
        }
        
        // Guardar cambios
        saveUserProgress()
    }
}