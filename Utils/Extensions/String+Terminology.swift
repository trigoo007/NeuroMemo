import Foundation

extension String {
    /// Intenta normalizar un término anatómico
    var normalizedAnatomicalTerm: String {
        return TerminologyMapper.shared.standardizeTerm(self)
    }
    
    /// Comprueba si la cadena contiene terminología anatómica
    var containsAnatomicalTerminology: Bool {
        return LanguageDetector.shared.isAnatomicalTerminology(self)
    }
    
    /// Extrae posibles términos anatómicos de un texto
    var extractedAnatomicalTerms: [String] {
        return LanguageDetector.shared.detectAnatomicalTerms(in: self)
    }
    
    /// Detecta el idioma del texto
    var detectedLanguage: String? {
        return LanguageDetector.shared.detectLanguage(for: self)
    }
    
    /// Intenta traducir el texto al español si no lo está ya
    func translateToSpanishIfNeeded(completion: @escaping (Result<String, Error>) -> Void) {
        // Si ya está en español o no se puede detectar, devolver el original
        guard let detectedLang = self.detectedLanguage, detectedLang != "es" else {
            completion(.success(self))
            return
        }
        
        // Traducir usando el servicio de traducción
        TranslationService.shared.translate(self, from: detectedLang, to: "es") { result in
            completion(result)
        }
    }
    
    /// Convierte la primera letra a mayúscula manteniendo el resto
    var capitalizedFirst: String {
        guard !self.isEmpty else { return self }
        return self.prefix(1).uppercased() + self.dropFirst()
    }
    
    /// Formatea un término anatómico para mostrar (primera letra mayúscula, sin espacios extras)
    var formattedAnatomicalTerm: String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.capitalizedFirst
    }
    
    /// Separa un texto en palabras individuales filtrando elementos vacíos
    var words: [String] {
        return self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }
    
    /// Comprueba similitud con otro texto (útil para comparar respuestas)
    func similarityScore(to other: String) -> Double {
        let selfLowercased = self.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let otherLowercased = other.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Si son idénticos
        if selfLowercased == otherLowercased {
            return 1.0
        }
        
        // Comparar por palabras comunes
        let selfWords = Set(selfLowercased.words)
        let otherWords = Set(otherLowercased.words)
        
        if selfWords.isEmpty || otherWords.isEmpty {
            return 0.0
        }
        
        let commonWords = selfWords.intersection(otherWords)
        let unionWords = selfWords.union(otherWords)
        
        // Calcular coeficiente de Jaccard
        return Double(commonWords.count) / Double(unionWords.count)
    }
    
    /// Comprueba si una respuesta es "suficientemente buena" comparada con la respuesta esperada
    func isGoodEnoughMatch(to expectedAnswer: String, threshold: Double = 0.7) -> Bool {
        return self.similarityScore(to: expectedAnswer) >= threshold
    }
    
    /// Elimina acentos y diacríticos (útil para búsquedas insensibles a acentos)
    var withoutAccents: String {
        return self.folding(options: .diacriticInsensitive, locale: .current)
    }
    
    /// Comprueba si el texto es una abreviatura conocida y devuelve su forma completa
    var expandedAbbreviation: String {
        // Diccionario de abreviaturas anatómicas comunes
        let abbreviations: [String: String] = [
            "SNC": "Sistema Nervioso Central",
            "SNP": "Sistema Nervioso Periférico",
            "NC": "Nervio Craneal",
            "NE": "Nervio Espinal",
            "N.": "Nervio",
            "A.": "Arteria",
            "V.": "Vena",
            "M.": "Músculo",
            "Lig.": "Ligamento",
            "N.C.": "Nervio Craneal",
            "Art.": "Articulación",
            "SNA": "Sistema Nervioso Autónomo",
            "SNS": "Sistema Nervioso Simpático"
        ]
        
        // Comprobar si coincide exactamente con alguna abreviatura
        if let expanded = abbreviations[self.trimmingCharacters(in: .whitespacesAndNewlines)] {
            return expanded
        }
        
        // Si no es una abreviatura conocida, devolver el original
        return self
    }
}