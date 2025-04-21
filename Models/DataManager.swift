import Foundation
import Combine

class DataManager: ObservableObject {
    // Servicios
    private let userDataManager = UserDataManager.shared
    private let coreDataManager = CoreDataManager.shared
    
    // Datos principales
    @Published var knowledgeBase: KnowledgeBase
    @Published var userProgress: UserProgress
    @Published var settings: UserSettings
    
    // Cancellables para gestionar suscripciones
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Inicializar los datos principales
        self.knowledgeBase = KnowledgeBase.shared
        self.userProgress = userDataManager.currentUser
        self.settings = userProgress.settings
        
        // Configurar suscripciones
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Escuchar cambios en UserDataManager
        userDataManager.$currentUser
            .sink { [weak self] updatedProgress in
                self?.userProgress = updatedProgress
                self?.settings = updatedProgress.settings
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Gestión de datos del usuario
    
    func saveUserProgress() {
        userDataManager.saveUserProgress(userProgress)
    }
    
    func updateUserSettings(_ newSettings: UserSettings) {
        userProgress.settings = newSettings
        saveUserProgress()
    }
    
    func recordStudySession(structureId: String, duration: TimeInterval) {
        userDataManager.recordStudySession(structureId: structureId, duration: duration)
    }
    
    func recordQuizAnswer(correct: Bool) {
        // Actualizar estadísticas locales
        userProgress.studyStats.correctAnswers += correct ? 1 : 0
        userProgress.studyStats.incorrectAnswers += correct ? 0 : 1
        
        // Guardar en UserDataManager
        userDataManager.recordQuizAnswer(correct: correct)
    }
    
    func recordGameCompletion(game: CompletedGame) {
        userProgress.completedGames.append(game)
        saveUserProgress()
    }
    
    func updateStructureFamiliarity(structureId: String, increment: Double) {
        if let index = knowledgeBase.structures.firstIndex(where: { $0.id == structureId }) {
            // Actualizar familiaridad en el modelo de datos
            knowledgeBase.structures[index].userFamiliarity += increment
            knowledgeBase.structures[index].userFamiliarity = min(1.0, max(0.0, knowledgeBase.structures[index].userFamiliarity))
            knowledgeBase.structures[index].lastStudied = Date()
            
            // Actualizar fecha de próxima revisión basada en SRS
            updateNextReviewDate(for: index)
        }
    }
    
    // MARK: - Funciones de consulta
    
    func getStructureById(_ id: String) -> AnatomicalStructure? {
        return knowledgeBase.getStructureById(id)
    }
    
    func getStructuresBySystem(_ system: String) -> [AnatomicalStructure] {
        return knowledgeBase.getStructuresBySystem(system)
    }
    
    func getStructuresByLevel(_ level: Int) -> [AnatomicalStructure] {
        return knowledgeBase.getStructuresByLevel(level)
    }
    
    func getAllSystems() -> [String] {
        return knowledgeBase.getAllSystems()
    }
    
    func getRelationshipsForStructure(_ structureId: String) -> [Relationship] {
        return knowledgeBase.getRelationshipsForStructure(structureId)
    }
    
    func getStudiedStructures() -> [StudiedStructure] {
        return userProgress.studiedStructures
    }
    
    func getCompletedGames() -> [CompletedGame] {
        return userProgress.completedGames
    }
    
    func getAchievements() -> [Achievement] {
        return userProgress.achievements
    }
    
    // MARK: - Funciones auxiliares
    
    private func updateNextReviewDate(for structureIndex: Int) {
        let structure = knowledgeBase.structures[structureIndex]
        let familiarity = structure.userFamiliarity
        
        // Calcular intervalo de revisión basado en la familiaridad
        // Más familiaridad = intervalos más largos
        let interval: TimeInterval
        if familiarity < 0.3 {
            interval = 24 * 3600 // 1 día
        } else if familiarity < 0.6 {
            interval = 3 * 24 * 3600 // 3 días
        } else if familiarity < 0.8 {
            interval = 7 * 24 * 3600 // 1 semana
        } else {
            interval = 14 * 24 * 3600 // 2 semanas
        }
        
        knowledgeBase.structures[structureIndex].nextReviewDate = Date(timeIntervalSinceNow: interval)
    }
    
    // Limpiar recursos al finalizar
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
} 