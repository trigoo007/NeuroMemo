import Foundation

class TerminologyMapper {
    static let shared = TerminologyMapper()
    
    // Diccionario de mapeo para normalizar variaciones terminológicas
    private var terminologyMap: [String: String] = [:]
    // Mapa inverso para búsquedas rápidas
    private var reverseMap: [String: Set<String>] = [:]
    
    private init() {
        loadTerminologyMaps()
    }
    
    /// Carga los mapas de terminología desde archivos de recursos
    private func loadTerminologyMaps() {
        guard let url = Bundle.main.url(forResource: "TerminologyStandardization", withExtension: "json") else {
            print("Advertencia: No se encontró el archivo TerminologyStandardization.json")
            loadDefaultMappings()
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let mappings = try decoder.decode([String: String].self, from: data)
            
            self.terminologyMap = mappings
            
            // Construir mapa inverso
            for (variant, standard) in mappings {
                if reverseMap[standard] == nil {
                    reverseMap[standard] = []
                }
                reverseMap[standard]?.insert(variant)
            }
            
            print("Mapa de terminología cargado: \(terminologyMap.count) términos")
        } catch {
            print("Error al cargar el mapa de terminología: \(error.localizedDescription)")
            loadDefaultMappings()
        }
    }
    
    /// Carga un conjunto predeterminado de mapeos de terminología
    private func loadDefaultMappings() {
        // Algunos mapeos básicos como ejemplo
        let defaultMappings: [String: String] = [
            // Variaciones en español
            "nervio optico": "nervio óptico",
            "medula espinal": "médula espinal",
            "bulbo raquideo": "bulbo raquídeo",
            "lobulo frontal": "lóbulo frontal",
            "lobulo occipital": "lóbulo occipital",
            "lobulo parietal": "lóbulo parietal",
            "lobulo temporal": "lóbulo temporal",
            // Variaciones comunes por errores ortográficos
            "hipotalamo": "hipotálamo",
            "talamo": "tálamo",
            "hipofisis": "hipófisis",
            "hipocampo": "hipocampo",
            "amigdala": "amígdala"
        ]
        
        self.terminologyMap = defaultMappings
        
        // Construir mapa inverso
        for (variant, standard) in defaultMappings {
            if reverseMap[standard] == nil {
                reverseMap[standard] = []
            }
            reverseMap[standard]?.insert(variant)
        }
        
        print("Mapa de terminología por defecto cargado: \(terminologyMap.count) términos")
    }
    
    /// Normaliza un término anatómico según los estándares
    /// - Parameter term: Término a normalizar
    /// - Returns: Término normalizado según los estándares establecidos
    func standardizeTerm(_ term: String) -> String {
        // Normalizar a minúsculas para la búsqueda
        let normalizedTerm = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Buscar en el mapa de terminología
        if let standardizedTerm = terminologyMap[normalizedTerm] {
            return standardizedTerm
        }
        
        // Si no hay una coincidencia exacta, buscar coincidencias parciales
        for (variant, standard) in terminologyMap {
            if normalizedTerm.contains(variant) {
                // Reemplazar solo la parte coincidente
                return normalizedTerm.replacingOccurrences(of: variant, with: standard)
            }
        }
        
        // Si no se encuentra, devolver el término original
        return term
    }
    
    /// Obtiene todas las variaciones conocidas de un término estándar
    /// - Parameter standardTerm: Término estándar
    /// - Returns: Conjunto de variaciones conocidas
    func getVariations(for standardTerm: String) -> Set<String> {
        let normalizedTerm = standardTerm.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return reverseMap[normalizedTerm] ?? []
    }
    
    /// Verifica si un término es una variación conocida
    /// - Parameter term: Término a verificar
    /// - Returns: Booleano indicando si es una variación conocida
    func isKnownVariation(_ term: String) -> Bool {
        let normalizedTerm = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return terminologyMap[normalizedTerm] != nil
    }
    
    /// Busca términos estándar que coincidan parcialmente con una consulta
    /// - Parameter query: Consulta de búsqueda
    /// - Returns: Lista de términos estándar que coinciden parcialmente
    func findMatchingTerms(for query: String) -> [String] {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var results = Set<String>()
        
        // Buscar en términos estándar
        for standard in reverseMap.keys {
            if standard.contains(normalizedQuery) || normalizedQuery.contains(standard) {
                results.insert(standard)
            }
        }
        
        // Buscar en variaciones
        for (variant, standard) in terminologyMap {
            if variant.contains(normalizedQuery) || normalizedQuery.contains(variant) {
                results.insert(standard)
            }
        }
        
        return Array(results).sorted()
    }
    
    /// Añade un nuevo mapeo de terminología
    /// - Parameters:
    ///   - variant: Variación del término
    ///   - standard: Término estándar
    func addTerminologyMapping(variant: String, standard: String) {
        let normalizedVariant = variant.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedStandard = standard.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        terminologyMap[normalizedVariant] = normalizedStandard
        
        if reverseMap[normalizedStandard] == nil {
            reverseMap[normalizedStandard] = []
        }
        reverseMap[normalizedStandard]?.insert(normalizedVariant)
        
        // En una implementación real, aquí también guardaríamos los cambios
        // en un archivo persistente o base de datos
    }
}