import Foundation

enum TranslationError: Error {
    case translationUnavailable
    case invalidSourceLanguage
    case invalidTargetLanguage
    case networkError
}

class TranslationService {
    static let shared = TranslationService()
    
    private let supportedLanguages = ["es", "en", "fr", "de", "it", "pt", "la"]
    private var terminologyDictionaries: [String: [String: String]] = [:]
    
    private init() {
        loadTerminologyDictionaries()
    }
    
    /// Carga los diccionarios de terminología desde archivos JSON
    private func loadTerminologyDictionaries() {
        for language in supportedLanguages {
            guard let url = Bundle.main.url(forResource: "Terminology_\(language)", withExtension: "json") else {
                print("Advertencia: No se encontró el diccionario para el idioma \(language)")
                continue
            }
            
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                if let dictionary = try decoder.decode([String: String].self, from: data) {
                    terminologyDictionaries[language] = dictionary
                    print("Diccionario de terminología cargado para \(language): \(dictionary.count) términos")
                }
            } catch {
                print("Error al cargar el diccionario para \(language): \(error.localizedDescription)")
            }
        }
    }
    
    /// Traduce un término anatómico de un idioma a otro
    /// - Parameters:
    ///   - term: El término a traducir
    ///   - sourceLanguage: Código ISO del idioma de origen (ej: "es", "en")
    ///   - targetLanguage: Código ISO del idioma de destino
    ///   - completion: Callback con el resultado de la traducción
    func translateTerm(_ term: String, from sourceLanguage: String, to targetLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Verificar que ambos idiomas estén soportados
        guard supportedLanguages.contains(sourceLanguage) else {
            completion(.failure(TranslationError.invalidSourceLanguage))
            return
        }
        
        guard supportedLanguages.contains(targetLanguage) else {
            completion(.failure(TranslationError.invalidTargetLanguage))
            return
        }
        
        // Si es el mismo idioma, devolver el término original
        if sourceLanguage == targetLanguage {
            completion(.success(term))
            return
        }
        
        // Primero, intentamos una traducción directa desde nuestro diccionario especializado
        if let sourceDictionary = terminologyDictionaries[sourceLanguage],
           let targetDictionary = terminologyDictionaries[targetLanguage] {
            
            // Buscar la clave estándar (en inglés generalmente) para este término
            if let standardKey = sourceDictionary.first(where: { $0.value.lowercased() == term.lowercased() })?.key {
                // Usar la clave estándar para buscar en el diccionario destino
                if let translation = targetDictionary[standardKey] {
                    completion(.success(translation))
                    return
                }
            }
        }
        
        // Si no tenemos una traducción directa, podemos usar una API online como fallback
        translateUsingOnlineService(term, from: sourceLanguage, to: targetLanguage) { result in
            completion(result)
        }
    }
    
    /// Traduce un término anatómico usando un servicio online (fallback)
    private func translateUsingOnlineService(_ term: String, from sourceLanguage: String, to targetLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        // En una implementación real, aquí se usaría una API de traducción
        // como Google Translate, DeepL, Azure Translator, etc.
        
        // Ejemplo simulado con un retardo para simular una llamada a la red
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // Simular una traducción básica para propósitos de demostración
            // En una app real, implementar la llamada a la API correspondiente
            let simulatedTranslation: String
            
            if term.lowercased() == "cerebro" && sourceLanguage == "es" && targetLanguage == "en" {
                simulatedTranslation = "brain"
            } else if term.lowercased() == "brain" && sourceLanguage == "en" && targetLanguage == "es" {
                simulatedTranslation = "cerebro"
            } else {
                // Simular una traducción añadiendo un sufijo
                simulatedTranslation = "\(term)_\(targetLanguage)"
            }
            
            DispatchQueue.main.async {
                completion(.success(simulatedTranslation))
            }
        }
    }
    
    /// Traduce la descripción completa de una estructura anatómica
    func translateStructureDescription(_ structure: AnatomicalStructure, to targetLanguage: String, completion: @escaping (Result<AnatomicalStructure, Error>) -> Void) {
        // Asumimos que las estructuras están originalmente en español
        let sourceLanguage = "es"
        
        // Evitar traducción innecesaria si ya está en el idioma objetivo
        if sourceLanguage == targetLanguage {
            completion(.success(structure))
            return
        }
        
        // Crear grupo de espera para todas las traducciones
        let dispatchGroup = DispatchGroup()
        
        // Variables mutables para almacenar los resultados de traducción
        var translatedName = structure.name
        var translatedDescription = structure.description
        var translatedLatinName = structure.latinName
        var translatedError: Error?
        
        // Traducir nombre
        dispatchGroup.enter()
        translateTerm(structure.name, from: sourceLanguage, to: targetLanguage) { result in
            switch result {
            case .success(let translated):
                translatedName = translated
            case .failure(let error):
                translatedError = error
            }
            dispatchGroup.leave()
        }
        
        // Traducir descripción (frases más largas)
        dispatchGroup.enter()
        translateUsingOnlineService(structure.description, from: sourceLanguage, to: targetLanguage) { result in
            switch result {
            case .success(let translated):
                translatedDescription = translated
            case .failure(let error):
                translatedError = error
            }
            dispatchGroup.leave()
        }
        
        // Nombre en latín generalmente no se traduce, pero podría adaptarse según convenciones locales
        if let latinName = structure.latinName {
            dispatchGroup.enter()
            translateTerm(latinName, from: "la", to: targetLanguage) { result in
                switch result {
                case .success(let translated):
                    translatedLatinName = translated
                case .failure:
                    // Mantener el nombre en latín original si falla la traducción
                    translatedLatinName = latinName
                }
                dispatchGroup.leave()
            }
        }
        
        // Cuando todas las traducciones terminen
        dispatchGroup.notify(queue: .main) {
            if let error = translatedError {
                completion(.failure(error))
                return
            }
            
            // Crear una copia de la estructura con los campos traducidos
            var translatedStructure = structure
            translatedStructure.name = translatedName
            translatedStructure.description = translatedDescription
            translatedStructure.latinName = translatedLatinName
            
            completion(.success(translatedStructure))
        }
    }
    
    /// Verifica si un idioma está soportado
    func isLanguageSupported(_ languageCode: String) -> Bool {
        return supportedLanguages.contains(languageCode)
    }
    
    /// Obtiene la lista de idiomas soportados
    func getSupportedLanguages() -> [String] {
        return supportedLanguages
    }
}