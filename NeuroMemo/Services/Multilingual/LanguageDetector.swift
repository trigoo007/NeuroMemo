// LanguageDetector.swift
import Foundation
import NaturalLanguage

class LanguageDetector {
    private let recognizer = NLLanguageRecognizer()
    private let supportedLanguages = ["es", "en", "la"] // Español, Inglés, Latín
    
    // Detectar idioma de un texto
    func detectLanguage(in text: String) -> String? {
        // Limpiar reconocedor previo
        recognizer.reset()
        
        // Procesar texto
        recognizer.processString(text)
        
        // Obtener hipótesis de idioma
        guard let languageCode = recognizer.dominantLanguage?.rawValue else {
            return nil
        }
        
        // Si es un idioma soportado, devolverlo
        if supportedLanguages.contains(languageCode) {
            return languageCode
        }
        
        // Si es latín (no reconocido directamente por NL), intentar detectarlo con heurísticas
        if isLikeLatin(text) {
            return "la"
        }
        
        // Si no es un idioma soportado, devolver el más probable de los soportados
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        
        for (language, _) in hypotheses.sorted(by: { $0.value > $1.value }) {
            if supportedLanguages.contains(language.rawValue) {
                return language.rawValue
            }
        }
        
        // Por defecto, español
        return "es"
    }
    
    // Determinar si un texto parece ser latín
    private func isLikeLatin(text: String) -> Bool {
        // Palabras comunes en latín para neuroanatomía
        let latinWords = [
            "cerebrum", "medulla", "nervus", "vena", "arteria", "musculus",
            "os", "cranium", "corpus", "ventriculus", "lobus", "cortex",
            "gyrus", "sulcus", "hippocampus", "thalamus", "cerebellum"
        ]
        
        // Si el texto contiene varias palabras latinas, probablemente sea latín
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let latinWordCount = words.filter { latinWords.contains($0) }.count
        
        return latinWordCount >= 2 || (latinWordCount > 0 && words.count < 5)
    }
    
    // Detectar idioma de una palabra o término
    func detectTermLanguage(_ term: String) -> String {
        // Para términos cortos, usar una heurística basada en patrones
        // Primero verificar si parece latín
        if isLikeLatin(text: term) {
            return "la"
        }
        
        // Verificar si contiene caracteres específicos del español
        let spanishChars = "áéíóúüñ"
        if term.lowercased().contains(where: { spanishChars.contains($0) }) {
            return "es"
        }
        
        // Si no hay pistas claras, usar el reconocedor
        guard let languageCode = detectLanguage(in: term) else {
            // Por defecto, español
            return "es"
        }
        
        return languageCode
    }
    
    // Determinar idioma predominante en un documento
    func detectDocumentLanguage(document: String) -> String {
        // Para documentos largos, dividir en párrafos y analizar cada uno
        let paragraphs = document.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        var languageCounts: [String: Int] = [:]
        
        for paragraph in paragraphs {
            if let language = detectLanguage(in: paragraph) {
                languageCounts[language, default: 0] += 1
            }
        }
        
        // Devolver el idioma más frecuente
        if let mostFrequent = languageCounts.max(by: { $0.value < $1.value }) {
            return mostFrequent.key
        }
        
        // Si no se puede determinar, usar el documento completo
        return detectLanguage(in: document) ?? "es"
    }
}
