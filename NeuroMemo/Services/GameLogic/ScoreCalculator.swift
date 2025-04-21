// ScoreCalculator.swift
import Foundation

enum DifficultyLevel: String {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
    
    var multiplier: Double {
        switch self {
        case .easy: return 0.8
        case .medium: return 1.0
        case .hard: return 1.3
        case .expert: return 1.6
        }
    }
}

class ScoreCalculator {
    // Calcular puntuación base
    func calculateScore(baseScore: Int, gameType: String, difficulty: DifficultyLevel = .medium, duration: TimeInterval = 0) -> Int {
        // Calcular multiplicador por dificultad
        let difficultyMultiplier = difficulty.multiplier
        
        // Diferentes fórmulas según el tipo de juego
        switch gameType {
        case "countdown":
            // Para contrarreloj, dar más valor a puntuaciones altas
            return Int(Double(baseScore) * difficultyMultiplier)
            
        case "touchandname":
            // Porcentaje sobre puntuación máxima
            let percentCorrect = Double(baseScore) / 10.0
            return Int(100 * percentCorrect * difficultyMultiplier)
            
        case "missinglabels":
            // Valor por cada etiqueta correcta
            return Int(Double(baseScore) * 20 * difficultyMultiplier)
            
        case "connections":
            // Conexiones correctas
            return Int(Double(baseScore) * 25 * difficultyMultiplier)
            
        default:
            // Cálculo genérico
            return Int(Double(baseScore) * 10 * difficultyMultiplier)
        }
    }
    
    // Calcular puntuación basada en tiempo
    func calculateTimeBasedScore(correctAnswers: Int, timeSpent: TimeInterval, gameType: String) -> Int {
        let baseScore = correctAnswers * 100
        
        // Si el tiempo es muy corto, dar bonificación
        let timeBonus: Double
        switch gameType {
        case "countdown":
            // No hay tiempo límite, el tiempo restante es el bonus
            timeBonus = 1.0
            
        default:
            // Menos tiempo = mejor puntuación
            if timeSpent < 30 {
                timeBonus = 1.5
            } else if timeSpent < 60 {
                timeBonus = 1.2
            } else if timeSpent < 120 {
                timeBonus = 1.0
            } else {
                timeBonus = 0.8
            }
        }
        
        return Int(Double(baseScore) * timeBonus)
    }
    
    // Calcular precisión
    func calculateAccuracy(correctAnswers: Int, totalAnswers: Int) -> Double {
        guard totalAnswers > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAnswers)
    }
    
    // Calcular puntuación de racha
    func calculateStreakScore(streak: Int) -> Int {
        // Bonificación exponencial por rachas largas
        if streak <= 1 {
            return 0
        } else if streak <= 3 {
            return 10 * streak
        } else if streak <= 7 {
            return 20 * streak
        } else {
            return 30 * streak
        }
    }
    
    // Calcular puntuación combinada para clasificación
    func calculateLeaderboardScore(gameScore: Int, accuracy: Double, streakDays: Int) -> Int {
        let accuracyBonus = Int(accuracy * 100)
        let streakBonus = calculateStreakScore(streak: streakDays)
        
        return gameScore + accuracyBonus + streakBonus
    }
}
