import Foundation

struct UserProgress {
    var userId: String
    var totalStudyTime: TimeInterval = 0
    var lastActiveDate: Date = Date()
    var studiedStructures: [StudiedStructure] = []
    var completedGames: [CompletedGame] = []
    var achievements: [Achievement] = []
    var settings: UserSettings = UserSettings()
    
    init(userId: String) {
        self.userId = userId
    }
}

struct StudiedStructure: Codable {
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

struct CompletedGame: Codable {
    var gameId: String
    var gameType: String // Identificador del tipo de juego (ej: "connectionGame", "touchAndName")
    var completionDate: Date
    var score: Double // Normalizado entre 0-100
    var timeSpent: TimeInterval
}

struct Achievement: Codable {
    var id: String
    var name: String
    var description: String
    var dateUnlocked: Date?
    
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