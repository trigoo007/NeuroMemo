import Foundation

class DifficultyManager {
    static let shared = DifficultyManager()
    
    // Niveles de dificultad disponibles
    enum DifficultyLevel: Int, CaseIterable, Codable {
        case beginner = 1
        case easy = 2
        case medium = 3
        case hard = 4
        case expert = 5
        
        var displayName: String {
            switch self {
            case .beginner: return "Principiante"
            case .easy: return "Fácil"
            case .medium: return "Medio"
            case .hard: return "Difícil"
            case .expert: return "Experto"
            }
        }
    }
    
    private(set) var currentLevel: DifficultyLevel = .medium
    private(set) var adaptiveMode: Bool = true
    
    // Parámetros para adaptación de dificultad
    private var consecutiveSuccesses = 0
    private var consecutiveFailures = 0
    private let thresholdForIncrease = 3
    private let thresholdForDecrease = 2
    
    private init() {
        // Cargar nivel guardado si existe
        loadSavedDifficulty()
    }
    
    // MARK: - Configuración de Dificultad
    
    func setDifficulty(_ level: DifficultyLevel) {
        currentLevel = level
        saveDifficulty()
    }
    
    func setAdaptiveMode(_ enabled: Bool) {
        adaptiveMode = enabled
        saveDifficulty()
    }
    
    // MARK: - Adaptación de Dificultad
    
    /// Notifica al gestor sobre el resultado de una interacción para ajustar la dificultad
    /// - Parameter success: Si la interacción fue exitosa
    /// - Returns: Booleano indicando si el nivel de dificultad cambió
    @discardableResult
    func recordInteractionResult(_ success: Bool) -> Bool {
        guard adaptiveMode else { return false }
        
        var difficultyChanged = false
        
        if success {
            consecutiveSuccesses += 1
            consecutiveFailures = 0
            
            // Aumentar dificultad si hay suficientes éxitos consecutivos
            if consecutiveSuccesses >= thresholdForIncrease && currentLevel != .expert {
                increaseDifficulty()
                difficultyChanged = true
                consecutiveSuccesses = 0
            }
        } else {
            consecutiveFailures += 1
            consecutiveSuccesses = 0
            
            // Disminuir dificultad si hay suficientes fallos consecutivos
            if consecutiveFailures >= thresholdForDecrease && currentLevel != .beginner {
                decreaseDifficulty()
                difficultyChanged = true
                consecutiveFailures = 0
            }
        }
        
        return difficultyChanged
    }
    
    /// Aumenta el nivel de dificultad en un paso
    func increaseDifficulty() {
        guard let nextLevel = DifficultyLevel(rawValue: currentLevel.rawValue + 1) else { return }
        currentLevel = nextLevel
        saveDifficulty()
    }
    
    /// Disminuye el nivel de dificultad en un paso
    func decreaseDifficulty() {
        guard let prevLevel = DifficultyLevel(rawValue: currentLevel.rawValue - 1) else { return }
        currentLevel = prevLevel
        saveDifficulty()
    }
    
    // MARK: - Persistencia
    
    private func loadSavedDifficulty() {
        if let savedLevel = UserDefaults.standard.object(forKey: "UserDifficultyLevel") as? Int,
           let level = DifficultyLevel(rawValue: savedLevel) {
            currentLevel = level
        }
        
        adaptiveMode = UserDefaults.standard.bool(forKey: "AdaptiveDifficultyEnabled")
    }
    
    private func saveDifficulty() {
        UserDefaults.standard.set(currentLevel.rawValue, forKey: "UserDifficultyLevel")
        UserDefaults.standard.set(adaptiveMode, forKey: "AdaptiveDifficultyEnabled")
    }
    
    // MARK: - Ajuste de Parámetros de Juego
    
    /// Ajusta el tiempo disponible para un juego según el nivel de dificultad actual
    /// - Parameter baseTime: Tiempo base en segundos
    /// - Returns: Tiempo ajustado en segundos
    func adjustTimeLimit(baseTime: TimeInterval) -> TimeInterval {
        let timeFactors: [DifficultyLevel: Double] = [
            .beginner: 2.0,   // El doble de tiempo
            .easy: 1.5,       // 50% más de tiempo
            .medium: 1.0,     // Tiempo base
            .hard: 0.8,       // 20% menos de tiempo
            .expert: 0.6      // 40% menos de tiempo
        ]
        
        let factor = timeFactors[currentLevel] ?? 1.0
        return baseTime * factor
    }
    
    /// Ajusta el número de opciones a mostrar según el nivel de dificultad
    /// - Parameter baseCount: Número base de opciones
    /// - Returns: Número ajustado de opciones
    func adjustOptionsCount(baseCount: Int) -> Int {
        let countFactors: [DifficultyLevel: Int] = [
            .beginner: -1,    // Una opción menos
            .easy: 0,         // Igual
            .medium: 1,       // Una opción más
            .hard: 2,         // Dos opciones más
            .expert: 3        // Tres opciones más
        ]
        
        let adjustment = countFactors[currentLevel] ?? 0
        return max(2, baseCount + adjustment) // Mínimo 2 opciones
    }
    
    /// Obtiene el nivel de detalle para mostrar en las pistas
    /// - Returns: Nivel de detalle (0-1) donde 1 es máximo detalle
    func getHintDetailLevel() -> Float {
        let detailLevels: [DifficultyLevel: Float] = [
            .beginner: 1.0,   // Pistas completas
            .easy: 0.8,       // 80% de detalle
            .medium: 0.6,     // 60% de detalle
            .hard: 0.3,       // 30% de detalle
            .expert: 0.1      // 10% de detalle (mínimas pistas)
        ]
        
        return detailLevels[currentLevel] ?? 0.6
    }
}