// TerminologyMapper.swift
import Foundation

class TerminologyMapper {
    // Tipos de terminología
    enum TerminologyType: String {
        case standard = "standard"
        case clinical = "clinical"
        case academic = "academic"
        case simplified = "simplified"
    }
    
    // Mapeo de términos según el tipo de terminología
    private var terminologyMappings: [String: [TerminologyType: String]] = [
        // Sistema nervioso
        "cerebro": [
            .standard: "cerebro",
            .clinical: "encéfalo",
            .academic: "encephalon",
            .simplified: "cerebro"
        ],
        "nervio": [
            .standard: "nervio",
                        .clinical: "nervio periférico",
                        .academic: "nervus",
                        .simplified: "nervio"
                    ],
                    "neurona": [
                        .standard: "neurona",
                        .clinical: "célula nerviosa",
                        .academic: "neuron",
                        .simplified: "célula del cerebro"
                    ],
                    "médula espinal": [
                        .standard: "médula espinal",
                        .clinical: "médula espinal",
                        .academic: "medulla spinalis",
                        .simplified: "médula"
                    ],
                    "cerebelo": [
                        .standard: "cerebelo",
                        .clinical: "cerebelo",
                        .academic: "cerebellum",
                        .simplified: "parte posterior del cerebro"
                    ],
                    "hipocampo": [
                        .standard: "hipocampo",
                        .clinical: "hipocampo",
                        .academic: "hippocampus",
                        .simplified: "centro de memoria"
                    ],
                    
                    // Sistema cardiovascular
                    "corazón": [
                        .standard: "corazón",
                        .clinical: "corazón",
                        .academic: "cor",
                        .simplified: "corazón"
                    ],
                    "arteria": [
                        .standard: "arteria",
                        .clinical: "arteria",
                        .academic: "arteria",
                        .simplified: "vaso sanguíneo que sale del corazón"
                    ],
                    "vena": [
                        .standard: "vena",
                        .clinical: "vena",
                        .academic: "vena",
                        .simplified: "vaso sanguíneo que va al corazón"
                    ],
                    
                    // Sistema digestivo
                    "estómago": [
                        .standard: "estómago",
                        .clinical: "estómago",
                        .academic: "ventriculus",
                        .simplified: "estómago"
                    ],
                    "hígado": [
                        .standard: "hígado",
                        .clinical: "hígado",
                        .academic: "hepar",
                        .simplified: "hígado"
                    ],
                    "intestino": [
                        .standard: "intestino",
                        .clinical: "intestino",
                        .academic: "intestinum",
                        .simplified: "intestino"
                    ]
                ]
                
                // Preferencia de terminología del usuario
                private var preferredTerminology: TerminologyType = .standard
                
                // Establecer preferencia de terminología
                func setPreferredTerminology(_ type: TerminologyType) {
                    preferredTerminology = type
                }
                
                // Obtener término según la preferencia del usuario
                func getPreferredTerm(for standardTerm: String) -> String {
                    if let mappings = terminologyMappings[standardTerm.lowercased()],
                       let term = mappings[preferredTerminology] {
                        return term
                    }
                    
                    // Si no se encuentra mapeo, devolver el término original
                    return standardTerm
                }
                
                // Convertir texto completo a la terminología preferida
                func convertTextToPreferredTerminology(_ text: String) -> String {
                    var convertedText = text
                    
                    // Ordenar términos por longitud (de mayor a menor) para evitar reemplazos parciales
                    let sortedTerms = terminologyMappings.keys.sorted(by: { $0.count > $1.count })
                    
                    for term in sortedTerms {
                        if let mappings = terminologyMappings[term],
                           let preferredTerm = mappings[preferredTerminology] {
                            
                            // Crear expresión regular para reemplazar palabras completas
                            let pattern = "\\b\(term)\\b"
                            
                            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                                let range = NSRange(location: 0, length: convertedText.utf16.count)
                                
                                // Aplicar reemplazo
                                convertedText = regex.stringByReplacingMatches(
                                    in: convertedText,
                                    options: [],
                                    range: range,
                                    withTemplate: preferredTerm
                                )
                            }
                        }
                    }
                    
                    return convertedText
                }
                
                // Convertir un término a todas las terminologías disponibles
                func getAllTerminologies(for term: String) -> [TerminologyType: String] {
                    if let mappings = terminologyMappings[term.lowercased()] {
                        return mappings
                    }
                    
                    // Si no se encuentra, devolver el mismo término para todas las terminologías
                    var result: [TerminologyType: String] = [:]
                    for type in TerminologyType.allCases {
                        result[type] = term
                    }
                    return result
                }
                
                // Agregar un nuevo término al mapeo
                func addTermMapping(_ term: String, mappings: [TerminologyType: String]) {
                    terminologyMappings[term.lowercased()] = mappings
                }
                
                // Verificar si un término tiene mapeo
                func hasMapping(for term: String) -> Bool {
                    return terminologyMappings[term.lowercased()] != nil
                }
            }

            // Extensión para hacer TerminologyType un caso iterable
            extension TerminologyMapper.TerminologyType: CaseIterable {}
