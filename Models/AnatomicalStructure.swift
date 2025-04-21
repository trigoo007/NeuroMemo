import Foundation

struct AnatomicalStructure: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var system: String
    var level: Int
    var latinName: String?
    var synonyms: [String]?
    var imageReferences: [String]?
    var tags: [String]?
    
    // Propiedades para presentación UI
    var difficulty: Int? // 1-5, donde 5 es el más difícil
    var importance: Int? // 1-5, donde 5 es el más importante
    
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
    )
}