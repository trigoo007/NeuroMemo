// TranslationService.swift
import Foundation

enum TranslationError: Error {
    case translationFailed
    case unsupportedLanguage
    case networkError
}

class TranslationService {
    // Idiomas soportados
    let supportedLanguages = ["es", "en", "la"] // Español, Inglés, Latín
    
    // Traducciones en caché para términos comunes
    private var translationCache: [String: [String: String]] = [:]
    
    // Simulación de servicio de traducción
    // En una app real, esto utilizaría un API de traducción
    func translateTerm(_ term: String, from sourceLanguage: String, to targetLanguage: String) -> Result<String, Error> {
        // Verificar que los idiomas están soportados
        guard supportedLanguages.contains(sourceLanguage),
              supportedLanguages.contains(targetLanguage) else {
            return .failure(TranslationError.unsupportedLanguage)
        }
        
        // Si es el mismo idioma, devolver el término original
        if sourceLanguage == targetLanguage {
            return .success(term)
        }
        
        // Verificar si tenemos traducción en caché
        if let cachedTranslations = translationCache[term],
           let translation = cachedTranslations[targetLanguage] {
            return .success(translation)
        }
        
        // Si no está en caché, buscar en el diccionario de términos
        if let translation = lookupTermInDictionary(term, from: sourceLanguage, to: targetLanguage) {
            // Guardar en caché
            cacheTranslation(term, language: sourceLanguage, translation: translation, targetLanguage: targetLanguage)
            return .success(translation)
        }
        
        // Si no encontramos traducción, devolver el término original
        return .success(term)
    }
    
    // Traducir múltiples términos a la vez
    func batchTranslate(_ terms: [String], from sourceLanguage: String, to targetLanguage: String) -> Result<[String: String], Error> {
        var translations: [String: String] = [:]
        
        for term in terms {
            let result = translateTerm(term, from: sourceLanguage, to: targetLanguage)
            
            switch result {
            case .success(let translation):
                translations[term] = translation
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(translations)
    }
    
    // Guardar traducción en caché
    private func cacheTranslation(_ term: String, language: String, translation: String, targetLanguage: String) {
        if translationCache[term] == nil {
            translationCache[term] = [:]
        }
        
        translationCache[term]?[targetLanguage] = translation
        
        // También guardar la traducción inversa
        if translationCache[translation] == nil {
            translationCache[translation] = [:]
        }
        
        translationCache[translation]?[language] = term
    }
    
    // Buscar término en diccionario (simulado)
    private func lookupTermInDictionary(_ term: String, from sourceLanguage: String, to targetLanguage: String) -> String? {
        // Diccionario simplificado de términos anatómicos
        let dictionary: [String: [String: String]] = [
            // Español
            "cerebro": ["en": "brain", "la": "cerebrum"],
            "corazón": ["en": "heart", "la": "cor"],
            "pulmón": ["en": "lung", "la": "pulmo"],
            "hígado": ["en": "liver", "la": "hepar"],
            "riñón": ["en": "kidney", "la": "ren"],
            "estómago": ["en": "stomach", "la": "ventriculus"],
            "intestino": ["en": "intestine", "la": "intestinum"],
            "hueso": ["en": "bone", "la": "os"],
            "músculo": ["en": "muscle", "la": "musculus"],
            "nervio": ["en": "nerve", "la": "nervus"],
            "arteria": ["en": "artery", "la": "arteria"],
            "vena": ["en": "vein", "la": "vena"],
            "neurona": ["en": "neuron", "la": "neuron"],
            
            // Inglés
            "brain": ["es": "cerebro", "la": "cerebrum"],
            "heart": ["es": "corazón", "la": "cor"],
            "lung": ["es": "pulmón", "la": "pulmo"],
            "liver": ["es": "hígado", "la": "hepar"],
            "kidney": ["es": "riñón", "la": "ren"],
            "stomach": ["es": "estómago", "la": "ventriculus"],
            "intestine": ["es": "intestino", "la": "intestinum"],
            "bone": ["es": "hueso", "la": "os"],
            "muscle": ["es": "músculo", "la": "musculus"],
            "nerve": ["es": "nervio", "la": "nervus"],
            "artery": ["es": "arteria", "la": "arteria"],
            "vein": ["es": "vena", "la": "vena"],
            "neuron": ["es": "neurona", "la": "neuron"],
            
            // Latín
            "cerebrum": ["es": "cerebro", "en": "brain"],
            "cor": ["es": "corazón", "en": "heart"],
            "pulmo": ["es": "pulmón", "en": "lung"],
            "hepar": ["es": "hígado", "en": "liver"],
            "ren": ["es": "riñón", "en": "kidney"],
            "ventriculus": ["es": "estómago", "en": "stomach"],
            "intestinum": ["es": "intestino", "en": "intestine"],
            "os": ["es": "hueso", "en": "bone"],
            "musculus": ["es": "músculo", "en": "muscle"],
            "nervus": ["es": "nervio", "en": "nerve"],
            "arteria": ["es": "arteria", "en": "artery"],
            "vena": ["es": "vena", "en": "vein"],
            "neuron": ["es": "neurona", "en": "neuron"]
        ]
        
        // Buscar término en minúsculas
        let lowerTerm = term.lowercased()
        
        if let translations = dictionary[lowerTerm],
           let translation = translations[targetLanguage] {
            // Preservar mayúsculas si el término original empieza por mayúscula
            if term.first?.isUppercase == true {
                return translation.prefix(1).uppercased() + translation.dropFirst()
            }
            return translation
        }
        
        return nil
    }
    
    // Traducir una descripción completa
    func translateText(_ text: String, from sourceLanguage: String, to targetLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        // En una app real, esto utilizaría un API de traducción
        // Por ahora, simulamos el proceso con un retraso
        
        DispatchQueue.global().async {
            // Simulación de proceso de traducción
            Thread.sleep(forTimeInterval: 0.5)
            
            // Traducción muy simplificada (solo para demostración)
            var translatedText = text
            
            // Dividir el texto en palabras
            let words = text.components(separatedBy: .whitespacesAndNewlines)
            
            for word in words {
                let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                
                if !cleanWord.isEmpty {
                    let result = self.translateTerm(cleanWord, from: sourceLanguage, to: targetLanguage)
                    
                    if case .success(let translation) = result, translation != cleanWord {
                        // Reemplazar la palabra manteniendo puntuación y mayúsculas
                        let range = translatedText.range(of: word)
                        if let range = range {
                            translatedText.replaceSubrange(range, with: translation)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(translatedText))
            }
        }
    }
}
