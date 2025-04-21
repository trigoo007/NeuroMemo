import Foundation

class KnowledgeBase {
    static let shared = KnowledgeBase()
    
    private(set) var structures: [AnatomicalStructure] = []
    private(set) var relationships: [Relationship] = []
    
    private init() {
        loadStructures()
        loadRelationships()
    }
    
    func loadStructures() {
        guard let url = Bundle.main.url(forResource: "BaseStructures", withExtension: "json") else {
            print("Error: No se pudo encontrar el archivo BaseStructures.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            structures = try decoder.decode([AnatomicalStructure].self, from: data)
            print("Estructuras cargadas correctamente: \(structures.count)")
        } catch {
            print("Error al cargar las estructuras: \(error.localizedDescription)")
            // Proporcionar algunas estructuras por defecto o lanzar una alerta al usuario
            structures = []
        }
    }
    
    func loadRelationships() {
        guard let url = Bundle.main.url(forResource: "Relationships", withExtension: "json") else {
            print("Error: No se pudo encontrar el archivo Relationships.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            relationships = try decoder.decode([Relationship].self, from: data)
            print("Relaciones cargadas correctamente: \(relationships.count)")
        } catch {
            print("Error al cargar las relaciones: \(error.localizedDescription)")
            // Proporcionar algunas relaciones por defecto o lanzar una alerta al usuario
            relationships = []
        }
    }
    
    func getStructureById(_ id: String) -> AnatomicalStructure? {
        return structures.first { $0.id == id }
    }
    
    func getStructuresBySystem(_ system: String) -> [AnatomicalStructure] {
        return structures.filter { $0.system == system }
    }
    
    func getRelationshipsForStructure(_ structureId: String) -> [Relationship] {
        return relationships.filter { $0.sourceId == structureId || $0.targetId == structureId }
    }
    
    func getAllSystems() -> [String] {
        let systemsSet = Set(structures.map { $0.system })
        return Array(systemsSet).sorted()
    }
    
    func getStructuresByLevel(_ level: Int) -> [AnatomicalStructure] {
        return structures.filter { $0.level == level }
    }
}

// Modelo para relaciones entre estructuras anatómicas
struct Relationship: Codable, Identifiable {
    var id: String
    var sourceId: String
    var targetId: String
    var type: RelationshipType
    var description: String
    
    enum RelationshipType: String, Codable {
        case partOf = "partOf"
        case connects = "connects"
        case supplies = "supplies"
        case innervates = "innervates"
        case adjacentTo = "adjacentTo"
    }
}