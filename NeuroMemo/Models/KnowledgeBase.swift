import Foundation

/// Clase para gestionar la base de conocimiento neuroanatómico
class KnowledgeBase {
    // Singletón para acceso global
    static let shared = KnowledgeBase()
    
    // Estructuras anatómicas
    private var structures: [UUID: AnatomicalStructure] = [:]
    
    // Relaciones entre estructuras
    private var relationships: [StructureRelationship] = []
    
    // Términos y sinónimos
    private var terminologyMap: [String: UUID] = [:]
    
    // Referencias cruzadas multilingües
    private var languageTerms: [String: [String: UUID]] = [:]
    
    // Inicialización privada para singletón
    private init() {
        loadBaseKnowledge()
    }
    
    // Cargar conocimiento base
    private func loadBaseKnowledge() {
        // En implementación real, cargaría desde JSON o base de datos
        loadStructures()
        loadRelationships()
        buildTerminologyMap()
    }
    
    // Cargar estructuras anatómicas
    private func loadStructures() {
        // Simulación: cargar desde archivo JSON
        if let path = Bundle.main.path(forResource: "BaseStructures", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                let loadedStructures = try decoder.decode([AnatomicalStructure].self, from: data)
                
                // Almacenar con ID como clave
                for structure in loadedStructures {
                    structures[structure.id] = structure
                }
                
                print("Cargadas \(loadedStructures.count) estructuras anatómicas")
            } catch {
                print("Error cargando estructuras: \(error)")
                createSampleStructures() // Fallback a datos de ejemplo
            }
        } else {
            print("Archivo BaseStructures.json no encontrado")
            createSampleStructures() // Fallback a datos de ejemplo
        }
    }
    
    // Cargar relaciones entre estructuras
    private func loadRelationships() {
        // Simulación: cargar desde archivo JSON
        if let path = Bundle.main.path(forResource: "Relationships", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decoder = JSONDecoder()
                relationships = try decoder.decode([StructureRelationship].self, from: data)
                
                print("Cargadas \(relationships.count) relaciones")
            } catch {
                print("Error cargando relaciones: \(error)")
                createSampleRelationships() // Fallback a datos de ejemplo
            }
        } else {
            print("Archivo Relationships.json no encontrado")
            createSampleRelationships() // Fallback a datos de ejemplo
        }
    }
    
    // Construir mapa de terminología
    private func buildTerminologyMap() {
        // Crear mapeo de términos a IDs de estructuras
        for (id, structure) in structures {
            // Nombre principal
            terminologyMap[structure.name.lowercased()] = id
            
            // Nombre en latín
            if let latinName = structure.latinName {
                terminologyMap[latinName.lowercased()] = id
            }
            
            // Nombres alternativos
            for altName in structure.alternativeNames {
                terminologyMap[altName.lowercased()] = id
            }
        }
        
        print("Mapa de terminología construido con \(terminologyMap.count) términos")
    }
    
    // MARK: - Métodos de acceso público
    
    /// Obtener todas las estructuras
    func getAllStructures() -> [AnatomicalStructure] {
        return Array(structures.values)
    }
    
    /// Obtener estructura por ID
    func getStructure(byId id: UUID) -> AnatomicalStructure? {
        return structures[id]
    }
    
    /// Obtener estructuras relacionadas con una estructura dada
    func getRelatedStructures(forId id: UUID) -> [AnatomicalStructure] {
        // Buscar relaciones que involucren a esta estructura
        let relatedIds = relationships
            .filter { $0.sourceId == id || $0.targetId == id }
            .map { $0.sourceId == id ? $0.targetId : $0.sourceId }
        
        // Obtener las estructuras correspondientes
        return relatedIds.compactMap { structures[$0] }
    }
    
    /// Buscar estructuras por término
    func findStructures(byTerm term: String) -> [AnatomicalStructure] {
        let normalizedTerm = term.lowercased()
        
        // Búsqueda exacta
        if let id = terminologyMap[normalizedTerm], let structure = structures[id] {
            return [structure]
        }
        
        // Búsqueda parcial
        let matchingIds = terminologyMap.compactMap { (key, id) -> UUID? in
            return key.contains(normalizedTerm) ? id : nil
        }
        
        // Eliminar duplicados y obtener estructuras
        return Array(Set(matchingIds)).compactMap { structures[$0] }
    }
    
    /// Obtener estructuras por sistema anatómico
    func getStructures(bySystem system: AnatomicalSystem) -> [AnatomicalStructure] {
        return structures.values.filter { $0.system == system }
    }
    
    /// Obtener estructuras por nivel anatómico
    func getStructures(byLevel level: AnatomicalLevel) -> [AnatomicalStructure] {
        return structures.values.filter { $0.level == level }
    }
    
    // MARK: - Datos de ejemplo
    
    /// Crear estructuras de ejemplo (solo para prototipo)
    private func createSampleStructures() {
        // Implementación con datos de muestra
        let structure1 = AnatomicalStructure(
            id: UUID(),
            name: "Corteza Prefrontal",
            latinName: "Cortex Praefrontalis",
            alternativeNames: ["Corteza frontal anterior", "PFC"],
            description: "La corteza prefrontal es la parte anterior del lóbulo frontal del cerebro.",
            system: .central,
            level: .cortex,
            relatedStructures: [],
            functionalRoles: ["Funciones ejecutivas", "Toma de decisiones"],
            clinicalRelevance: "Asociada con trastornos como la esquizofrenia y TDAH.",
            difficultyLevel: 3,
            examFrequency: 0.85,
            imageReferences: []
        )
        
        structures[structure1.id] = structure1
        
        // Agregar más estructuras...
    }
    
    /// Crear relaciones de ejemplo (solo para prototipo)
    private func createSampleRelationships() {
        // Implementación con datos de muestra si se tienen estructuras
        if structures.count >= 2 {
            let ids = Array(structures.keys)
            relationships.append(StructureRelationship(
                id: UUID(),
                sourceId: ids[0],
                targetId: ids[1],
                type: .anatomical,
                description: "Conexión anatómica"
            ))
        }
    }
}

/// Tipo de relación entre estructuras
struct StructureRelationship: Identifiable, Codable {
    let id: UUID
    let sourceId: UUID
    let targetId: UUID
    let type: RelationshipType
    let description: String
}

/// Tipos de relaciones entre estructuras
enum RelationshipType: String, Codable {
    case anatomical = "Anatómica"     // Conexión física
    case functional = "Funcional"     // Conexión funcional
    case hierarchy = "Jerárquica"     // Relación parte-todo
    case pathway = "Vía"              // Parte de una vía neural
    case vascular = "Vascular"        // Suministro vascular
}
