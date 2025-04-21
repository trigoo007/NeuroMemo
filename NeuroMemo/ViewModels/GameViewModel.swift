// GameViewModel.swift
import Foundation
import Combine

class GameViewModel: ObservableObject {
    // Servicios y dependencias
    private let knowledgeBase: KnowledgeBase
    private let userDataManager: UserDataManager
    private let spacedRepetition: SpacedRepetitionEngine
    private let scoreCalculator: ScoreCalculator
    private let difficultyManager: DifficultyManager
    
    // Estado publicado
    @Published var availableStructures: [AnatomicalStructure] = []
    @Published var currentGameType: String?
    @Published var gameActive = false
    @Published var difficulty: DifficultyLevel = .medium
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        knowledgeBase: KnowledgeBase = KnowledgeBase.shared,
        userDataManager: UserDataManager = UserDataManager.shared,
        spacedRepetition: SpacedRepetitionEngine = SpacedRepetitionEngine.shared,
        scoreCalculator: ScoreCalculator = ScoreCalculator(),
        difficultyManager: DifficultyManager = DifficultyManager()
    ) {
        self.knowledgeBase = knowledgeBase
        self.userDataManager = userDataManager
        self.spacedRepetition = spacedRepetition
        self.scoreCalculator = scoreCalculator
        self.difficultyManager = difficultyManager
        
        // Cargar estructuras disponibles
        loadAvailableStructures()
    }
    
    func loadAvailableStructures() {
        // Obtener las estructuras que el usuario ha estudiado y las que están pendientes de repaso
        let dueItems = spacedRepetition.getDueItems(for: userDataManager.currentUser.id)
        let studiedItems = userDataManager.currentUser.studiedStructures
        
        // Combinar estructuras para juegos
        if studiedItems.count < 10 {
            // Si hay pocas estructuras estudiadas, usar todas las disponibles
            availableStructures = knowledgeBase.getAllStructures()
        } else {
            // Priorizar las estructuras que necesitan repaso
            var structures = dueItems
            
            // Añadir algunas estructuras aleatorias estudiadas
            let randomStudied = studiedItems.shuffled().prefix(10)
            structures.append(contentsOf: randomStudied)
            
            // Asegurar que no hay duplicados
            availableStructures = Array(Set(structures))
        }
    }
    
    func startGame(type: String) {
        currentGameType = type
        gameActive = true
        
        // Ajustar dificultad basada en el historial del usuario
        difficulty = difficultyManager.getDifficultyForUser(
            userId: userDataManager.currentUser.id,
            gameType: type
        )
        
        // Actualizar estructuras disponibles
        loadAvailableStructures()
    }
    
    func exitGame() {
        currentGameType = nil
        gameActive = false
    }
    
    func getRandomStructure() -> AnatomicalStructure? {
        return availableStructures.randomElement()
    }
    
    func getRandomStructures(count: Int) -> [AnatomicalStructure] {
        let shuffled = availableStructures.shuffled()
        return Array(shuffled.prefix(min(count, shuffled.count)))
    }
    
    func getRandomLabeledImage() -> AnatomicalImage? {
        // Obtener una imagen aleatoria con etiquetas
        let images = knowledgeBase.getLabeledImages()
        return images.randomElement()
    }
    
    func getRelatedStructuresForGame() -> (structures: [AnatomicalStructure], connections: [Connection]) {
        var gameStructures: [AnatomicalStructure] = []
        var gameConnections: [Connection] = []
        
        // Obtener una estructura base
        if let baseStructure = getRandomStructure() {
            gameStructures.append(baseStructure)
            
            // Obtener estructuras relacionadas
            let related = knowledgeBase.getRelatedStructures(for: baseStructure.id)
            gameStructures.append(contentsOf: related)
            
            // Crear conexiones
            for relatedStructure in related {
                gameConnections.append(Connection(
                    from: baseStructure.id,
                    to: relatedStructure.id,
                    relationship: "relacionado"
                ))
            }
            
            // Añadir algunas estructuras no relacionadas
            let additional = getRandomStructures(count: 2).filter { structure in
                !gameStructures.contains(where: { $0.id == structure.id })
            }
            gameStructures.append(contentsOf: additional)
            
            // Limitar a un máximo de 8 estructuras
            if gameStructures.count > 8 {
                gameStructures = Array(gameStructures.prefix(8))
            }
        }
        
        return (structures: gameStructures, connections: gameConnections)
    }
    
    func recordCorrectAnswer(structure: AnatomicalStructure) {
        // Registrar respuesta correcta
        userDataManager.recordQuizAnswer(correct: true)
        
        // Actualizar en el sistema de repetición espaciada
        spacedRepetition.recordSuccessfulReview(itemId: structure.id, userId: userDataManager.currentUser.id)
    }
    
    func recordIncorrectAnswer(structure: AnatomicalStructure) {
        // Registrar respuesta incorrecta
        userDataManager.recordQuizAnswer(correct: false)
        
        // Actualizar en el sistema de repetición espaciada
        spacedRepetition.recordFailedReview(itemId: structure.id, userId: userDataManager.currentUser.id)
    }
    
    func saveGameResults(gameType: String, score: Int, duration: TimeInterval) {
        // Calcular puntuación ajustada por dificultad
        let finalScore = scoreCalculator.calculateScore(
            baseScore: score,
            gameType: gameType,
            difficulty: difficulty,
            duration: duration
        )
        
        // Crear registro de juego completado
        let completedGame = CompletedGame(
            id: UUID().uuidString,
            gameType: gameType,
            score: finalScore,
            date: Date(),
            difficulty: difficulty.rawValue,
            duration: duration
        )
        
        // Guardar en el perfil del usuario
        userDataManager.recordGameCompletion(game: completedGame)
        
        // Ajustar dificultad para próximos juegos
        difficultyManager.updateDifficulty(
            userId: userDataManager.currentUser.id,
            gameType: gameType,
            score: score,
            maxPossibleScore: gameType == "countdown" ? 0 : 10 // Para contrarreloj no hay puntuación máxima
        )
    }
    
    func speakText(_ text: String) {
        // Implementar reproducción de texto a voz
        // Esta es una implementación simulada
        print("Speaking: \(text)")
    }
}
