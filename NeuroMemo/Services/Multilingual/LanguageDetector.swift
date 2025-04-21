import Foundation
import NaturalLanguage

class LanguageDetector {
    static let shared = LanguageDetector()
    
    private init() {}
    
    /// Detecta el idioma más probable de un texto
    /// - Parameter text: Texto a analizar
    /// - Returns: Código ISO del idioma detectado, o nil si no se pudo detectar
    func detectLanguage(for text: String) -> String? {
        // Usar NaturalLanguage framework para la detección
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        // Obtener el idioma más probable
        guard let languageCode = recognizer.dominantLanguage?.rawValue else {
            return nil
        }
        
        return languageCode
    }
    
    /// Detecta el idioma y nivel de confianza
    /// - Parameter text: Texto a analizar
    /// - Returns: Tupla con el código de idioma y nivel de confianza (0-1), o nil si no se pudo detectar
    func detectLanguageWithConfidence(for text: String) -> (languageCode: String, confidence: Double)? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        // Obtener todos los idiomas candidatos con sus probabilidades
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        
        // Encontrar el idioma con mayor probabilidad
        guard let topLanguage = hypotheses.max(by: { $0.value < $1.value }) else {
            return nil
        }
        
        return (topLanguage.key.rawValue, topLanguage.value)
    }
    
    /// Verifica si un texto contiene terminología anatómica
    /// - Parameter text: Texto a analizar
    /// - Returns: Booleano indicando si se detectó terminología anatómica
    func isAnatomicalTerminology(_ text: String) -> Bool {
        // Lista de palabras clave que podrían indicar terminología anatómica
        let anatomicalKeywords = [
            // Español
            "cerebro", "médula", "ganglio", "nervio", "neurona", "glía", "axón", "dendrita",
            "corteza", "cerebelo", "mesencéfalo", "diencéfalo", "tálamo", "hipotálamo",
            // Inglés
            "brain", "spinal", "ganglion", "nerve", "neuron", "glia", "axon", "dendrite",
            "cortex", "cerebellum", "midbrain", "diencephalon", "thalamus", "hypothalamus",
            // Latín
            "cerebrum", "medulla", "ganglion", "nervus", "neuron", "glia", "axon", "dendritum"
        ]
        
        // Convertir texto a minúsculas para comparación insensible a mayúsculas
        let lowercasedText = text.lowercased()
        
        // Verificar si alguna palabra clave está presente en el texto
        for keyword in anatomicalKeywords {
            if lowercasedText.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    /// Detecta términos anatómicos en un texto y sugiere posibles coincidencias
    func detectAnatomicalTerms(in text: String) -> [String] {
        // En una implementación real, esto podría usar procesamiento de lenguaje natural
        // más avanzado para identificar términos anatómicos específicos
        
        // Simplificación: dividir por palabras y verificar contra una lista de términos conocidos
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        // Términos anatómicos conocidos (simplificado)
        let knownTerms = KnowledgeBase.shared.structures.flatMap { structure -> [String] in
            var terms = [structure.name]
            if let latinName = structure.latinName {
                terms.append(latinName)
            }
            if let synonyms = structure.synonyms {
                terms.append(contentsOf: synonyms)
            }
            return terms
        }
        
        // Buscar coincidencias aproximadas
        var detectedTerms: [String] = []
        
        for word in words {
            for term in knownTerms {
                // Usar distancia de Levenshtein para coincidencias parciales
                let similarity = calculateSimilarity(between: word.lowercased(), and: term.lowercased())
                if similarity > 0.8 { // Umbral de similitud alto
                    detectedTerms.append(term)
                    break
                }
            }
        }
        
        return detectedTerms
    }
    
    /// Calcula la similitud entre dos strings (algoritmo de distancia de Levenshtein)
    private func calculateSimilarity(between s1: String, and s2: String) -> Double {
        // Implementación simple de distancia de Levenshtein normalizada
        let empty = [Int](repeating: 0, count: s2.count + 1)
        var last = [Int](0...s2.count)
        
        for (i, c1) in s1.enumerated() {
            var current = [i + 1] + empty
            for (j, c2) in s2.enumerated() {
                current[j + 1] = c1 == c2 ? last[j] : min(last[j], last[j + 1], current[j]) + 1
            }
            last = current
        }
        
        let maxLength = max(s1.count, s2.count)
        guard maxLength > 0 else { return 1.0 } // Dos strings vacíos son idénticos
        
        // Normalizar: 1.0 significa coincidencia perfecta, 0.0 significa totalmente diferentes
        let similarity = 1.0 - (Double(last.last!) / Double(maxLength))
        return similarity
    }
}