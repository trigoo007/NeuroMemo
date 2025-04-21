import Foundation

class ScoreCalculator {
    static let shared = ScoreCalculator()
    
    // Factores para diferentes cálculos de puntuación
    private let baseDifficultyMultiplier: [DifficultyManager.DifficultyLevel: Double] = [
        .beginner: 0.8,
        .easy: 1.0,
        .medium: 1.5,
        .hard: 2.0,
        .expert: 3.0
    ]
    
    private let timeBonus: [DifficultyManager.DifficultyLevel: Double] = [
        .beginner: 0.5,
        .easy: 0.8,
        .medium: 1.0,
        .hard: 1.5,
        .expert: 2.0
    ]
    
    private let streakMultiplier = 0.1 // 10% extra por cada acierto consecutivo
    private let minimumBaseScore = 10.0
    private let maximumBaseScore = 100.0
    
    private init() {}
    
    /// Calcula la puntuación para un juego de identificación anatómica
    /// - Parameters:
    ///   - correctAnswers: Número de respuestas correctas
    ///   - totalQuestions: Número total de preguntas
    ///   - timeUsed: Tiempo usado en segundos
    ///   - timeLimit: Tiempo límite en segundos
    ///   - difficultyLevel: Nivel de dificultad actual
    /// - Returns: Puntuación calculada
    func calculateIdentificationGameScore(
        correctAnswers: Int,
        totalQuestions: Int,
        timeUsed: TimeInterval,
        timeLimit: TimeInterval,
        difficultyLevel: DifficultyManager.DifficultyLevel
    ) -> Double {
        guard totalQuestions > 0 else { return 0 }
        
        // Porcentaje de aciertos
        let accuracy = Double(correctAnswers) / Double(totalQuestions)
        
        // Puntuación base según precisión
        let baseScore = accuracy * maximumBaseScore
        
        // Multiplicador por dificultad
        let difficultyMultiplier = baseDifficultyMultiplier[difficultyLevel] ?? 1.0
        
        // Bonificación por velocidad (si ha terminado dentro del límite)
        var timeMultiplier = 1.0
        if timeUsed < timeLimit {
            let timeUsageRatio = timeUsed / timeLimit
            let timeBonus = 1.0 - (timeUsageRatio * 0.5) // Máximo 50% de bonificación por tiempo
            timeMultiplier = 1.0 + (timeBonus * (self.timeBonus[difficultyLevel] ?? 1.0))
        }
        
        // Cálculo final
        let finalScore = baseScore * difficultyMultiplier * timeMultiplier
        
        // Redondear a entero más cercano
        return round(finalScore)
    }
    
    /// Calcula la puntuación para un juego de conexión de estructuras
    /// - Parameters:
    ///   - correctConnections: Número de conexiones correctas
    ///   - totalConnections: Número total de conexiones posibles
    ///   - wrongAttempts: Número de intentos incorrectos
    ///   - difficultyLevel: Nivel de dificultad actual
    /// - Returns: Puntuación calculada
    func calculateConnectionGameScore(
        correctConnections: Int,
        totalConnections: Int,
        wrongAttempts: Int,
        difficultyLevel: DifficultyManager.DifficultyLevel
    ) -> Double {
        guard totalConnections > 0 else { return 0 }
        
        // Puntuación base por conexiones correctas
        let baseScore = Double(correctConnections) / Double(totalConnections) * maximumBaseScore
        
        // Penalización por intentos fallidos
        let errorPenalty = min(0.5, Double(wrongAttempts) * 0.05) // Máximo 50% de penalización
        
        // Multiplicador por dificultad
        let difficultyMultiplier = baseDifficultyMultiplier[difficultyLevel] ?? 1.0
        
        // Cálculo final
        let finalScore = baseScore * (1.0 - errorPenalty) * difficultyMultiplier
        
        // Redondear a entero más cercano
        return round(finalScore)
    }
    
    /// Calcula la puntuación para una sesión de estudio espaciada (SRS)
    /// - Parameters:
    ///   - responseQuality: Calidad de respuesta (0-5, donde 5 es perfecto)
    ///   - itemDifficulty: Dificultad del elemento estudiado (1-5)
    ///   - streak: Secuencia de respuestas correctas consecutivas
    /// - Returns: Puntuación calculada
    func calculateSpacedRepetitionScore(
        responseQuality: Int,
        itemDifficulty: Int,
        streak: Int
    ) -> Double {
        // Puntuación base según calidad de respuesta
        let baseScore = Double(responseQuality) / 5.0 * maximumBaseScore
        
        // Modificador por dificultad del ítem
        let difficultyModifier = Double(itemDifficulty) / 3.0
        
        // Bonificación por racha
        let streakBonus = min(1.0, Double(streak) * streakMultiplier)
        
        // Cálculo final
        let finalScore = baseScore * difficultyModifier * (1.0 + streakBonus)
        
        // Asegurar que sea al menos la puntuación mínima si la respuesta fue correcta
        return responseQuality >= 3 ? max(minimumBaseScore, round(finalScore)) : round(finalScore)
    }
    
    /// Calcula el total de puntos de experiencia (XP) para subir de nivel
    /// - Parameter level: Nivel actual
    /// - Returns: Puntos necesarios para el siguiente nivel
    func xpRequiredForNextLevel(from level: Int) -> Int {
        // Fórmula de crecimiento exponencial para niveles
        let baseXP = 100
        let growthFactor = 1.8
        
        // XP = baseXP * (growthFactor ^ (level - 1))
        return Int(Double(baseXP) * pow(growthFactor, Double(level - 1)))
    }
    
    /// Convierte una puntuación de juego en puntos de experiencia (XP)
    /// - Parameters:
    ///   - gameScore: Puntuación del juego
    ///   - gameType: Tipo de juego
    /// - Returns: Puntos de experiencia ganados
    func convertScoreToXP(gameScore: Double, gameType: String) -> Int {
        // Factores de conversión según tipo de juego
        let conversionFactors: [String: Double] = [
            "identification": 0.5,  // Juego de identificación
            "connection": 0.7,      // Juego de conexión
            "quiz": 1.0,            // Cuestionario
            "spatialTest": 1.2,     // Test espacial 3D
            "speedChallenge": 1.5   // Desafío contrarreloj
        ]
        
        let factor = conversionFactors[gameType] ?? 1.0
        
        // Conversión base: 1 punto de score = 1 XP (modificado por el factor)
        return Int(round(gameScore * factor))
    }
}