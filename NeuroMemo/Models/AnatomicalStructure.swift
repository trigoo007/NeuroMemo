import Foundation

struct AnatomicalStructure: Codable, Identifiable, Equatable {
    var id: String // Cambiado de UUID a String para coincidir con JSON
    var name: String
    var description: String
    var system: String // Cambiado de AnatomicalSystem a String
    var level: Int // Cambiado de AnatomicalLevel a Int
    var latinName: String?
    var synonyms: [String]? // Renombrado de alternativeNames
    var imageReferences: [String]?
    var tags: [String]? // Nueva propiedad
    var functionalRoles: [String]?
    var clinicalRelevance: String?
    var relatedStructures: [String]? // Nueva propiedad, tipo cambiado a [String]

    // Propiedades para presentación UI
    var difficulty: Int? // Renombrado de difficultyLevel
    var importance: Int? // Nueva propiedad
    var examFrequency: Double?

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

    static func == (lhs: AnatomicalStructure, rhs: AnatomicalStructure) -> Bool {
        lhs.id == rhs.id
    }

    // Ejemplo para inicialización rápida en pruebas
    static let example = AnatomicalStructure(
        id: "cerebrum",
        name: "Cerebro",
        description: "El cerebro es el centro del sistema nervioso central y es el órgano más complejo del cuerpo humano.",
        system: "Sistema Nervioso Central",
        level: 2,
        latinName: "Cerebrum",
        synonyms: ["Telencéfalo", "Encéfalo anterosuperior"],
        imageReferences: ["cerebrum_lateral", "cerebrum_medial"],
        tags: ["corteza", "hemisferios", "lóbulos"]
        // Faltan otras propiedades del ejemplo original, pero se pueden añadir si es necesario
    )
}

// Nota: Los enums AnatomicalSystem y AnatomicalLevel se han eliminado de este archivo.
// Si son necesarios en otras partes, deberían definirse en un archivo separado o
// refactorizar el código para usar los tipos String/Int directamente.
