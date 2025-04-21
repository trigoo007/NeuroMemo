import Foundation

/// Modelo para seguimiento del progreso del usuario
struct UserProgress: Codable {
    var userId: String
    var totalStudyTime: TimeInterval = 0
    var sessionsCompleted: Int = 0
    var lastSessionDate: Date?
    var structuresMastered: Int = 0
    var totalStructuresStudied: Int = 0
    var achievements: [Achievement] = []
    var level: Int = 1
    var experiencePoints: Int = 0
    var streakDays: Int = 0
    var lastStreakDate: Date?
    
    // Estadísticas por sistema anatómico
    var systemProgress: [AnatomicalSystem: SystemProgress] = [:]
    
    // Estadísticas por modo de juego
    var gameStats: [GameType: GameStatistics] = [:]
    
    // Cálculo de progreso general
    var overallProgress: Double {
        return totalStructuresStudied > 0 ?
            Double(structuresMastered) / Double(totalStructuresStudied) : 0.0
    }
    
    // Verificar si continúa la racha diaria
    mutating func checkStreak() {
        guard let lastDate = lastStreakDate else {
            lastStreakDate = Date()
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
            lastStreakDate = Date()
        } else {
            // Se rompió la racha
            streakDays = 1
            lastStreakDate = Date()
        }
    }
}

/// Progreso específico para cada sistema anatómico
struct SystemProgress: Codable {
    var totalStructures: Int = 0
    var masteredStructures: Int = 0
    var lastStudied: Date?
    var studyTimeForSystem: TimeInterval = 0
    var averageAccuracy: Double = 0.0
    
    var progressPercentage: Double {
        return totalStructures > 0 ?
            Double(masteredStructures) / Double(totalStructures) * 100.0 : 0.0
    }
}

/// Tipos de juegos disponibles en la aplicación
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

/// Estadísticas para cada tipo de juego
struct GameStatistics: Codable {
    var gamesPlayed: Int = 0
    var highScore: Int = 0
    var totalScore: Int = 0
    var correctAnswers: Int = 0
    var incorrectAnswers: Int = 0
    var averageResponseTime: TimeInterval = 0
    var lastPlayed: Date?
    var bestStreak: Int = 0
    
    // Cálculo de precisión
    var accuracy: Double {
        let total = correctAnswers + incorrectAnswers
        return total > 0 ? Double(correctAnswers) / Double(total) * 100.0 : 0.0
    }
}

/// Modelo para los logros desbloqueables
struct Achievement: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var iconName: String
    var unlockedDate: Date?
    var progress: Double = 0.0  // Progreso hacia el logro (0-1)
    var requirementValue: Int   // Valor necesario para desbloquear
    var currentValue: Int = 0   // Valor actual
    var category: AchievementCategory
    var tier: AchievementTier
    
    var isUnlocked: Bool {
        return unlockedDate != nil
    }
    
    // Actualizar progreso
    mutating func updateProgress(_ newValue: Int) {
        currentValue = newValue
        progress = min(1.0, Double(currentValue) / Double(requirementValue))
        
        if progress >= 1.0 && unlockedDate == nil {
            unlockedDate = Date()
        }
    }
}

/// Categorías para los diferentes logros
enum AchievementCategory: String, Codable, CaseIterable {
    case study = "Estudio"
    case mastery = "Dominio"
    case streak = "Constancia"
    case speed = "Velocidad"
    case accuracy = "Precisión"
    case exploration = "Exploración"
}

/// Niveles de logros
enum AchievementTier: String, Codable, CaseIterable {
    case bronze = "Bronce"
    case silver = "Plata"
    case gold = "Oro"
    case platinum = "Platino"
    case diamond = "Diamante"
}
