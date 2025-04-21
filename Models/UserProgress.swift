import Foundation

// Estructura para configuraciones de visualización
struct VisualizationSettings: Codable {
    var showLabels: Bool = true
    var highlightStructures: Bool = true
    var colorScheme: ColorScheme = .standard
    
    enum ColorScheme: String, Codable {
        case standard
        case highContrast
        case colorblindFriendly
    }
}

// Estructura para configuraciones del usuario
struct UserSettings: Codable {
    var language: String = "es"
    var notificationsEnabled: Bool = true
    var visualizationSettings: VisualizationSettings = VisualizationSettings()
    var reviewIntervals: [Int] = [1, 3, 7, 14, 30, 90, 180]
}

// Estructura para estadísticas de estudio
struct StudyStats: Codable {
    var totalStudyTime: TimeInterval = 0
    var correctAnswers: Int = 0
    var incorrectAnswers: Int = 0
    
    var accuracyPercentage: String {
        let total = correctAnswers + incorrectAnswers
        if total == 0 { return "N/A" }
        let percentage = (Double(correctAnswers) / Double(total)) * 100
        return "\(Int(percentage))%"
    }
}

// Estructura principal de progreso del usuario
struct UserProgress: Codable {
    var userId: String
    var username: String = "Usuario"
    var totalStudyTime: TimeInterval = 0
    var lastActiveDate: Date = Date()
    var lastStudyDate: Date?
    var streakDays: Int = 0
    var studiedStructures: [StudiedStructure] = []
    var completedGames: [CompletedGame] = []
    var achievements: [Achievement] = []
    var settings: UserSettings = UserSettings()
    var studyStats: StudyStats = StudyStats()
    
    init(userId: String) {
        self.userId = userId
    }
    
    // Verificar si continúa la racha diaria
    mutating func checkStreak() {
        guard let lastDate = lastStudyDate else {
            lastStudyDate = Date()
            streakDays = 1
            return
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) {
            return
        } else if calendar.isDateInYesterday(lastDate) {
            streakDays += 1
            lastStudyDate = Date()
        } else {
            streakDays = 1
            lastStudyDate = Date()
        }
    }
}

// Estructura para estructuras estudiadas
struct StudiedStructure: Codable, Identifiable {
    var id: String { structureId }
    var structureId: String
    var timeStudied: TimeInterval
    var lastReviewDate: Date
    var confidenceLevel: Int // 1-10
    
    init(structureId: String, timeStudied: TimeInterval, lastReviewDate: Date, confidenceLevel: Int) {
        self.structureId = structureId
        self.timeStudied = timeStudied
        self.lastReviewDate = lastReviewDate
        self.confidenceLevel = max(1, min(10, confidenceLevel))
    }
}

// Estructura para juegos completados
struct CompletedGame: Codable, Identifiable {
    var id: String { gameId }
    var gameId: String
    var gameType: String
    var completionDate: Date
    var score: Double
    var timeSpent: TimeInterval
}

// Estructura para logros
struct Achievement: Codable, Identifiable {
    var id: String
    var name: String
    var description: String
    var dateUnlocked: Date?
    var viewed: Bool = false
    
    var isUnlocked: Bool {
        return dateUnlocked != nil
    }
}

// Tipos de juegos disponibles en la aplicación
enum GameType: String, Codable, CaseIterable {
    case freeStudy = "Estudio Libre"
    case countdown = "Contrarreloj"
    case touchAndName = "Toca y Nombra"
    case missingLabels = "Rótulos Faltantes"
    case connections = "Conexiones Anatómicas"
    
    // Descripción de cada juego
    var description: String {
        switch self {
        case .freeStudy:
            return "Exploración libre de estructuras sin presión de tiempo"
        case .countdown:
            return "Identifica estructuras rápidamente contra el reloj"
        case .touchAndName:
            return "Toca estructuras y nómbralas correctamente"
        case .missingLabels:
            return "Completa las etiquetas que faltan en las imágenes"
        case .connections:
            return "Conecta estructuras relacionadas anatómicamente"
        }
    }
}

// Categorías para los diferentes logros
enum AchievementCategory: String, Codable, CaseIterable {
    case study = "Estudio"
    case mastery = "Dominio"
    case streak = "Constancia"
    case speed = "Velocidad"
    case accuracy = "Precisión"
    case exploration = "Exploración"
}