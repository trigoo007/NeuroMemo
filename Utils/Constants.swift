import Foundation
import SwiftUI

/// Constantes utilizadas en la aplicación NeuroMemo
struct Constants {
    /// Configuración de la aplicación
    struct App {
        static let name = "NeuroMemo"
        static let bundleId = "com.neuromemo.app"
        static let appGroup = "group.com.neuromemo.app"
        static let minSupportedVersion = "1.0.0"
        static let feedbackEmail = "contacto@neuromemo.com"
        static let privacyPolicyURL = "https://www.neuromemo.com/privacidad"
        static let termsOfServiceURL = "https://www.neuromemo.com/terminos"
    }
    
    /// Configuración de la interfaz de usuario
    struct UI {
        /// Padding estándar para vistas
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        /// Radios de borde para elementos de UI
        static let standardCornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 20
        
        /// Tiempos de animación
        static let quickAnimation: Double = 0.2
        static let standardAnimation: Double = 0.3
        static let slowAnimation: Double = 0.5
        
        /// Tamaños de elementos
        static let buttonHeight: CGFloat = 50
        static let iconSize: CGFloat = 24
        static let largeIconSize: CGFloat = 36
        static let thumbnailSize: CGFloat = 80
        static let avatarSize: CGFloat = 100
        
        /// Tamaños de texto
        static let titleFontSize: CGFloat = 24
        static let headerFontSize: CGFloat = 20
        static let bodyFontSize: CGFloat = 16
        static let captionFontSize: CGFloat = 14
        static let noteFontSize: CGFloat = 12
        
        /// Opacidad
        static let disabledOpacity: CGFloat = 0.6
        static let hintOpacity: CGFloat = 0.8
        static let overlayOpacity: CGFloat = 0.7
    }
    
    /// Configuración del juego
    struct Game {
        /// Niveles de dificultad
        static let difficultyLevels = ["Principiante", "Fácil", "Medio", "Difícil", "Experto"]
        
        /// Tiempos de juego (en segundos)
        static let quickGameDuration: TimeInterval = 120
        static let standardGameDuration: TimeInterval = 300
        static let longGameDuration: TimeInterval = 600
        
        /// Puntuación
        static let baseScorePerCorrectAnswer: Int = 100
        static let penaltyPerHint: Int = 20
        static let timeBonus: Int = 10 // Por segundo restante
        static let streakBonus: Int = 50 // Por respuesta correcta consecutiva
        
        /// Repetición espaciada
        static let minimumRepetitionInterval: TimeInterval = 3600 // 1 hora
        static let optimalRepetitionIntervals: [TimeInterval] = [
            3600 * 4,       // 4 horas
            3600 * 24,      // 1 día
            3600 * 24 * 3,  // 3 días
            3600 * 24 * 7,  // 1 semana
            3600 * 24 * 14, // 2 semanas
            3600 * 24 * 30  // 1 mes
        ]
        
        /// Límites
        static let maxHintsPerQuestion: Int = 3
        static let maxQuestionsPerSession: Int = 20
        static let minQuestionsForStreak: Int = 5
    }
    
    /// Rutas de archivos y directorios
    struct Paths {
        static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        static let temporaryDirectory = FileManager.default.temporaryDirectory
        static let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        static let userDataDirectory = documentsDirectory.appendingPathComponent("UserData")
        static let imagesDirectory = documentsDirectory.appendingPathComponent("Images")
        static let tempImagesDirectory = temporaryDirectory.appendingPathComponent("TempImages")
        static let exportDirectory = temporaryDirectory.appendingPathComponent("Export")
        
        /// Nombres de archivo
        static let knowledgeBaseFilename = "knowledge_base.json"
        static let userProgressFilename = "user_progress.json"
        static let settingsFilename = "settings.json"
        static let structuresDataFilename = "structures.json"
        static let relationshipsDataFilename = "relationships.json"
    }
    
    /// Claves de UserDefaults
    struct UserDefaultsKeys {
        static let isFirstLaunch = "isFirstLaunch"
        static let lastVersion = "lastVersion"
        static let userLanguage = "userLanguage"
        static let appTheme = "appTheme"
        static let notificationsEnabled = "notificationsEnabled"
        static let lastStudySession = "lastStudySession"
        static let dailyGoal = "dailyGoal"
        static let userProficiency = "userProficiency"
        static let preferredDifficulty = "preferredDifficulty"
        static let enableHaptics = "enableHaptics"
        static let enableVoiceFeedback = "enableVoiceFeedback"
        static let lastBackupDate = "lastBackupDate"
        static let sessionCount = "sessionCount"
        static let totalStudyTime = "totalStudyTime"
        static let enableFileLogging = "enableFileLogging"
    }
    
    /// Mensajes para el usuario
    struct Messages {
        /// Mensajes de éxito
        static let successPrefix = "¡Éxito! "
        static let saveSuccess = "Los datos se han guardado correctamente."
        static let importSuccess = "Los datos se han importado correctamente."
        static let exportSuccess = "Los datos se han exportado correctamente."
        static let loginSuccess = "Has iniciado sesión correctamente."
        static let signupSuccess = "Tu cuenta se ha creado correctamente."
        
        /// Mensajes de error
        static let errorPrefix = "Error: "
        static let genericError = "Ha ocurrido un error inesperado. Por favor, inténtalo de nuevo."
        static let networkError = "Error de conexión. Por favor, verifica tu conexión a Internet."
        static let authError = "Error de autenticación. Por favor, inicia sesión nuevamente."
        static let dataLoadError = "No se pudieron cargar los datos. Por favor, reinicia la aplicación."
        static let invalidInputError = "Los datos introducidos no son válidos. Por favor, verifica la información."
        static let permissionError = "No se han concedido los permisos necesarios."
        
        /// Mensajes de confirmación
        static let confirmationPrefix = "Confirmar: "
        static let deleteConfirmation = "¿Estás seguro de que quieres eliminar este elemento? Esta acción no se puede deshacer."
        static let logoutConfirmation = "¿Estás seguro de que quieres cerrar sesión?"
        static let resetConfirmation = "¿Estás seguro de que quieres reiniciar todos los datos? Esta acción no se puede deshacer."
        
        /// Mensajes de juego
        static let correctAnswer = "¡Correcto!"
        static let incorrectAnswer = "Incorrecto. Inténtalo de nuevo."
        static let almostCorrect = "Casi correcto. Inténtalo de nuevo."
        static let timesUp = "¡Se acabó el tiempo!"
        static let newHighScore = "¡Nuevo récord personal!"
        static let streakAchieved = "¡Racha de %d respuestas correctas!"
        static let levelUp = "¡Has subido al nivel %@!"
        
        /// Mensajes de estudio
        static let studyReminder = "Es hora de repasar tus estructuras anatómicas."
        static let goalAchieved = "¡Has alcanzado tu meta diaria de estudio!"
        static let reviewSuggestion = "Estas estructuras necesitan repaso: %@"
    }
    
    /// Configuración de notificaciones
    struct Notifications {
        static let studyReminderCategory = "STUDY_REMINDER"
        static let achievementCategory = "ACHIEVEMENT"
        static let reviewCategory = "REVIEW"
        
        static let studyReminderInterval: TimeInterval = 24 * 3600 // 24 horas
        static let maxNotificationsPerDay: Int = 3
        static let defaultReminderHour: Int = 18 // 6 PM
    }
    
    /// Configuración de la base de conocimientos
    struct KnowledgeBase {
        static let minStructuresForBasicProficiency: Int = 20
        static let minRelationshipsForBasicProficiency: Int = 30
        
        static let brainRegions = [
            "Telencéfalo",
            "Diencéfalo",
            "Mesencéfalo",
            "Protuberancia",
            "Bulbo raquídeo",
            "Cerebelo",
            "Médula espinal"
        ]
        
        static let anatomicalPlanes = [
            "Sagital",
            "Coronal (Frontal)",
            "Axial (Transversal)"
        ]
        
        static let nervousSystemDivisions = [
            "Sistema nervioso central",
            "Sistema nervioso periférico",
            "Sistema nervioso autónomo"
        ]
        
        static let cranialNerves = [
            "I - Olfatorio",
            "II - Óptico",
            "III - Motor ocular común",
            "IV - Troclear",
            "V - Trigémino",
            "VI - Motor ocular externo",
            "VII - Facial",
            "VIII - Vestibulococlear",
            "IX - Glosofaríngeo",
            "X - Vago",
            "XI - Accesorio",
            "XII - Hipogloso"
        ]
    }
    
    /// Configuración de seguridad
    struct Security {
        static let encryptionKey = "NEUROMEMO_ENCRYPTION_KEY"
        static let authTokenKey = "AUTH_TOKEN"
        static let maxLoginAttempts: Int = 5
        static let lockoutDuration: TimeInterval = 300 // 5 minutos
    }
}