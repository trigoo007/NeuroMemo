import Foundation

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
    var studyStats = StudyStats()
    
    // Estadísticas de estudio
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
            // Ya se actualizó hoy
            return
        } else if calendar.isDateInYesterday(lastDate) {
            // Continúa la racha
            streakDays += 1
            lastStudyDate = Date()
        } else {
            // Se rompió la racha
            streakDays = 1
            lastStudyDate = Date()
        }
    }
}

struct StudiedStructure: Codable, Identifiable {
    var id: String { structureId }
    var structureId: String
    var timeStudied: TimeInterval
    var lastReviewDate: Date
    var confidenceLevel: Int // 1-10, donde 10 es el máximo nivel de confianza
    
    init(structureId: String, timeStudied: TimeInterval, lastReviewDate: Date, confidenceLevel: Int) {
        self.structureId = structureId
        self.timeStudied = timeStudied
        self.lastReviewDate = lastReviewDate
        self.confidenceLevel = max(1, min(10, confidenceLevel)) // Limitar entre 1-10
    }
}

struct CompletedGame: Codable, Identifiable {
    var id: String { gameId }
    var gameId: String
    var gameType: String // Identificador del tipo de juego (ej: "connectionGame", "touchAndName")
    var completionDate: Date
    var score: Double // Normalizado entre 0-100
    var timeSpent: TimeInterval
}

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

struct UserSettings: Codable {
    var language: String = "es"
    var notificationsEnabled: Bool = true
    var visualizationSettings: VisualizationSettings = VisualizationSettings()
    var reviewIntervals: [Int] = [1, 3, 7, 14, 30, 90, 180] // Días entre revisiones basado en nivel de confianza
}

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