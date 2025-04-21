import Foundation
import UIKit

/// Constantes globales para la aplicación
struct Constants {
    
    // MARK: - Dimensiones de UI
    struct UI {
        static let cornerRadius: CGFloat = 12.0
        static let standardPadding: CGFloat = 16.0
        static let smallPadding: CGFloat = 8.0
        static let buttonHeight: CGFloat = 44.0
        static let iconSize: CGFloat = 24.0
        static let cardMinHeight: CGFloat = 120.0
        static let maxImagePreviewHeight: CGFloat = 300.0
        static let animationDuration: Double = 0.3
    }
    
    // MARK: - Colores
    struct Colors {
        static let primaryColor = UIColor(red: 0.4, green: 0.2, blue: 0.6, alpha: 1.0) // Morado
        static let secondaryColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0) // Azul
        static let accentColor = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0) // Naranja
        static let successColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0) // Verde
        static let errorColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0) // Rojo
        
        static let difficultyColors: [UIColor] = [
            UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0), // Verde (muy fácil)
            UIColor(red: 0.3, green: 0.6, blue: 0.8, alpha: 1.0), // Azul (fácil)
            UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0), // Amarillo (medio)
            UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0), // Naranja (difícil)
            UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)  // Rojo (muy difícil)
        ]
    }
    
    // MARK: - Tiempo
    struct Time {
        static let defaultSessionDuration: TimeInterval = 20 * 60 // 20 minutos
        static let shortBreakDuration: TimeInterval = 5 * 60 // 5 minutos
        static let longBreakDuration: TimeInterval = 15 * 60 // 15 minutos
        static let minimumStudyInterval: TimeInterval = 24 * 60 * 60 // 1 día
        static let defaultQuizTimeout: TimeInterval = 30.0 // 30 segundos
    }
    
    // MARK: - Almacenamiento
    struct Storage {
        static let userDefaultsPrefix = "com.neuromemo."
        static let documentsFolderName = "NeuroMemoData"
        static let imagesFolderName = "Images"
        static let modelsFolderName = "MLModels"
        static let whisperModelName = "whisper-small.mlmodel"
        static let segmentationModelName = "segmentation.mlmodel"
        static let maxImageSize = 2048 // píxeles
    }
    
    // MARK: - URLs y API
    struct Network {
        static let termsOfServiceURL = URL(string: "https://neuromemo.app/terms")!
        static let privacyPolicyURL = URL(string: "https://neuromemo.app/privacy")!
        static let supportURL = URL(string: "https://neuromemo.app/support")!
    }
    
    // MARK: - Gamificación
    struct Gamification {
        static let basePointsPerAnswer = 10
        static let streakMultiplier = 0.1 // 10% extra por respuesta en racha
        static let timeBonus = 0.5 // Hasta 50% extra por respuesta rápida
        static let experiencePerLevel = 1000 // XP necesarios para subir de nivel
        static let maxLevel = 50
        static let achievements = [
            Achievement(id: UUID(), title: "Primer Paso", description: "Completa tu primera sesión de estudio", iconName: "figure.walk", requirementValue: 1, category: .study, tier: .bronze),
            Achievement(id: UUID(), title: "Racha Inicial", description: "Estudia 3 días seguidos", iconName: "flame", requirementValue: 3, category: .streak, tier: .bronze),
            Achievement(id: UUID(), title: "Velocista", description: "Responde 10 preguntas correctamente en menos de 3 segundos cada una", iconName: "bolt", requirementValue: 10, category: .speed, tier: .silver)
            // Más logros...
        ]
    }
    
    // MARK: - Mensajes de Error
    struct ErrorMessages {
        static let networkError = "No se pudo conectar al servidor. Por favor, verifica tu conexión a internet."
        static let processingError = "Error al procesar la imagen. Por favor, inténtalo de nuevo."
        static let cameraError = "No se pudo acceder a la cámara. Verifica los permisos en Configuración."
        static let voiceRecognitionError = "Error al iniciar el reconocimiento de voz. Verifica los permisos del micrófono."
        static let dataLoadError = "Error al cargar los datos. Por favor, reinicia la aplicación."
    }
}
