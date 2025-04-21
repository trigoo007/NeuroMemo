import Foundation
import CoreData

struct AnatomicalStructure: Identifiable, Codable {
    let id: UUID
    var name: String
    var latinName: String?
    var alternativeNames: [String]
    var description: String
    var system: AnatomicalSystem
    var level: AnatomicalLevel
    var relatedStructures: [UUID]
    var functionalRoles: [String]
    var clinicalRelevance: String
    var difficultyLevel: Int
    var examFrequency: Double
    var imageReferences: [String]
    
    // Datos para el sistema de estudio
    var userFamiliarity: Double = 0.0
    var lastStudied: Date?
    var nextReviewDate: Date?
    var correctAnswers: Int = 0
    var incorrectAnswers: Int = 0
    
    // Cálculo de la tasa de acierto
    var successRate: Double {
        let total = correctAnswers + incorrectAnswers
        return total > 0 ? Double(correctAnswers) / Double(total) : 0.0
    }
}

enum AnatomicalSystem: String, Codable, CaseIterable {
    case central = "Sistema Nervioso Central"
    case peripheral = "Sistema Nervioso Periférico"
    case vascular = "Sistema Vascular Cerebral"
    case ventricular = "Sistema Ventricular"
    case limbic = "Sistema Límbico"
    case sensory = "Sistemas Sensoriales"
    case motor = "Sistemas Motores"
    case autonomic = "Sistema Nervioso Autónomo"
    case meningeal = "Sistema Meníngeo"
    case other = "Otros Sistemas"
    
    var iconName: String {
        switch self {
        case .central: return "brain"
        case .peripheral: return "nerve"
        case .vascular: return "artery"
        case .ventricular: return "flask"
        case .limbic: return "heart.circle"
        case .sensory: return "eye"
        case .motor: return "figure.walk"
        case .autonomic: return "waveform.path.ecg"
        case .meningeal: return "shield"
        case .other: return "questionmark.circle"
        }
    }
}

enum AnatomicalLevel: String, Codable, CaseIterable {
    case system = "Sistema"
    case region = "Región"
    case nucleus = "Núcleo"
    case tract = "Tracto"
    case cortex = "Corteza"
    case gyrus = "Giro"
    case sulcus = "Surco"
    case nerve = "Nervio"
    case vessel = "Vaso"
    case cellular = "Estructura Celular"
    case microscopic = "Estructura Microscópica"
    
    static let orderedLevels: [AnatomicalLevel] = [
        .system, .region, .cortex, .gyrus, .sulcus, .nucleus, .tract, .nerve, .vessel, .cellular, .microscopic
    ]
}
