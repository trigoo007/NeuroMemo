// DifficultyManager.swift
import Foundation

class DifficultyManager {
    private let userDefaultsKey = "com.neuromemo.userDifficulties"
    
    // Obtener dificultad recomendada para un usuario en un tipo de juego
    func getDifficultyForUser(userId: String, gameType: String) -> DifficultyLevel {
        let userPreferences = getUserPreferences()
        
        // Verificar si hay una dificultad guardada para este usuario y juego
        if let userSettings = userPreferences[userId],
           let gameDifficulty = userSettings[gameType] {
            return DifficultyLevel(rawValue: gameDifficulty) ?? .medium
        }
        
        // Por defecto, comenzar en dificultad media
        return .medium
    }
    
    // Actualizar dificultad basada en el rendimiento
    func updateDifficulty(userId: String, gameType: String, score: Int, maxPossibleScore: Int) {
        let currentDifficulty = getDifficultyForUser(userId: userId, gameType: gameType)
        var newDifficulty = currentDifficulty
        
        // Calcular porcentaje de éxito
        let successPercent: Double
        if maxPossibleScore > 0 {
            successPercent = Double(score) / Double(maxPossibleScore)
        } else {
            // Para juegos como contrarreloj
            successPercent = score >= 15 ? 0.9 : Double(score) / 15.0
        }
        
        // Ajustar dificultad basada en el rendimiento
        if successPercent > 0.8 {
            // Muy buen rendimiento, aumentar dificultad
            switch currentDifficulty {
            case .easy:
                newDifficulty = .medium
            case .medium:
                newDifficulty = .hard
            case .hard:
                newDifficulty = .expert
            case .expert:
                newDifficulty = .expert
            }
        } else if successPercent < 0.4 {
            // Mal rendimiento, reducir dificultad
            switch currentDifficulty {
            case .easy:
                newDifficulty = .easy
            case .medium:
                newDifficulty = .easy
            case .hard:
                newDifficulty = .medium
            case .expert:
                newDifficulty = .hard
            }
        }
        
        // Si ha cambiado, guardar nueva dificultad
        if newDifficulty != currentDifficulty {
            saveUserDifficulty(userId: userId, gameType: gameType, difficulty: newDifficulty)
        }
    }
    
    // Guardar dificultad para un usuario y juego
    private func saveUserDifficulty(userId: String, gameType: String, difficulty: DifficultyLevel) {
        var userPreferences = getUserPreferences()
        
        // Crear o actualizar preferencias del usuario
        if var userSettings = userPreferences[userId] {
            userSettings[gameType] = difficulty.rawValue
            userPreferences[userId] = userSettings
        } else {
            userPreferences[userId] = [gameType: difficulty.rawValue]
        }
        
        // Guardar en UserDefaults
        if let encoded = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // Obtener preferencias de todos los usuarios
    private func getUserPreferences() -> [String: [String: String]] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    // Reiniciar dificultad para un usuario
    func resetUserDifficulty(userId: String) {
        var userPreferences = getUserPreferences()
        userPreferences[userId] = nil
        
        if let encoded = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    // Sugerir dificultad basada en experiencia
    func suggestDifficultyForNewUser(previousExperience: String) -> DifficultyLevel {
        switch previousExperience.lowercased() {
        case "ninguna", "principiante":
            return .easy
        case "intermedia":
            return .medium
        case "avanzada", "experto":
            return .hard
        default:
            return .medium
        }
    }
    
    // Sugerir dificultad personalizada basada en categoría
    func suggestDifficultyForCategory(userId: String, category: String) -> DifficultyLevel {
        // Obtener progreso del usuario en esta categoría
        // Implementación simplificada - en una app real se analizaría el progreso real
        
        let userPreferences = getUserPreferences()
        let userGameHistory = userPreferences[userId] ?? [:]
        
        // Si el usuario ha jugado varios juegos, sugerir dificultad más alta
        if userGameHistory.count > 3 {
            return .hard
        } else if userGameHistory.count > 1 {
            return .medium
        } else {
            return .easy
        }
    }
}
