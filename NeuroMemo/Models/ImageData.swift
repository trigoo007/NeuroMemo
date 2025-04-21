import Foundation
import UIKit

struct AnatomicalImage: Identifiable, Codable {
    let id: UUID
    var fileName: String
    var title: String
    var description: String
    var modality: ImageModality
    var orientation: ImageOrientation
    var tags: [String]
    var labeledStructures: [LabeledStructure]?
    var creationDate: Date
    var isUserImported: Bool
    var sourceAttribution: String?
    
    // Información de procesamiento
    var hasBeenProcessed: Bool = false
    var enhancementApplied: Bool = false
    var ocrPerformed: Bool = false
}

struct LabeledStructure: Identifiable, Codable {
    let id: UUID
    var structureId: UUID
    var name: String
    var coordinates: CGPoint
    var boundingBox: CGRect?
    var contourPoints: [CGPoint]?
    var confidence: Double?
    var isUserCreated: Bool
}

enum ImageModality: String, Codable, CaseIterable {
    case mri = "Resonancia Magnética"
    case ct = "Tomografía Computarizada"
    case angiography = "Angiografía"
    case pet = "Tomografía por Emisión de Positrones"
    case illustration = "Ilustración"
    case diagram = "Diagrama"
    case histology = "Histología"
    case other = "Otra"
    
    var iconName: String {
        switch self {
        case .mri: return "scanner"
        case .ct: return "xray"
        case .angiography: return "artery"
        case .pet: return "atom"
        case .illustration: return "paintbrush"
        case .diagram: return "chart.pie"
        case .histology: return "microscope"
        case .other: return "questionmark.circle"
        }
    }
}

enum ImageOrientation: String, Codable, CaseIterable {
    case axial = "Axial"
    case coronal = "Coronal"
    case sagittal = "Sagital"
    case oblique = "Oblicua"
    case threeD = "3D"
    case other = "Otra"
}
