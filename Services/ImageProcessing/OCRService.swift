import Foundation
import Vision
import UIKit

enum OCRError: Error {
    case processingFailed
    case noTextFound
    case invalidImage
}

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// Reconoce texto en una imagen anatómica
    /// - Parameters:
    ///   - image: UIImage que contiene la imagen anatómica con texto
    ///   - region: Opcional, región específica donde buscar texto
    ///   - completion: Callback con el resultado del reconocimiento
    func recognizeText(in image: UIImage, region: CGRect? = nil, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        // Crear solicitud de reconocimiento de texto
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.processingFailed))
                return
            }
            
            // Procesar los resultados
            let recognizedStrings = observations.compactMap { observation -> String? in
                // Obtener el candidato de texto con mayor confianza
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return candidate.string
            }
            
            // Si no se encontró texto, devolver un error
            if recognizedStrings.isEmpty {
                completion(.failure(OCRError.noTextFound))
            } else {
                completion(.success(recognizedStrings))
            }
        }
        
        // Configurar opciones de reconocimiento
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["es", "en", "la"] // Español, inglés, latín (para términos anatómicos)
        
        // Si se especificó una región, limitar la búsqueda
        let handler: VNImageRequestHandler
        if let region = region {
            // Convertir CGRect a coordenadas normalizadas (0-1)
            let normalizedRect = CGRect(
                x: region.origin.x / image.size.width,
                y: region.origin.y / image.size.height,
                width: region.size.width / image.size.width,
                height: region.size.height / image.size.height
            )
            
            // Invertir coordenada Y (Vision usa 0 en la parte inferior)
            let visionRect = CGRect(
                x: normalizedRect.origin.x,
                y: 1 - normalizedRect.origin.y - normalizedRect.size.height,
                width: normalizedRect.size.width,
                height: normalizedRect.size.height
            )
            
            request.regionOfInterest = visionRect
            handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        } else {
            handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        }
        
        // Realizar el reconocimiento
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Reconoce etiquetas anatómicas en una imagen e intenta mapearlas a estructuras conocidas
    func recognizeAnatomicalLabels(in image: UIImage, completion: @escaping (Result<[(String, AnatomicalStructure?)], Error>) -> Void) {
        // Primero, usar OCR para reconocer todo el texto en la imagen
        recognizeText(in: image) { result in
            switch result {
            case .success(let recognizedTexts):
                // Procesar cada texto reconocido y tratar de mapearlo a estructuras conocidas
                let mappedStructures = self.mapRecognizedTextsToStructures(recognizedTexts)
                completion(.success(mappedStructures))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Intenta mapear textos reconocidos a estructuras anatómicas conocidas
    private func mapRecognizedTextsToStructures(_ texts: [String]) -> [(String, AnatomicalStructure?)] {
        var mappings: [(String, AnatomicalStructure?)] = []
        
        // Obtener todas las estructuras de la base de conocimiento
        let structures = KnowledgeBase.shared.structures
        
        for text in texts {
            // Normalizar el texto para la comparación (quitar acentos, convertir a minúsculas)
            let normalizedText = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()
            
            // Buscar la estructura más similar
            var bestMatch: AnatomicalStructure?
            var bestScore = 0.0
            
            for structure in structures {
                // Verificar nombre principal
                let nameScore = self.calculateSimilarity(between: normalizedText, and: structure.name.lowercased())
                if nameScore > bestScore && nameScore > 0.7 { // Umbral de similitud
                    bestScore = nameScore
                    bestMatch = structure
                }
                
                // Verificar nombre en latín
                if let latinName = structure.latinName?.lowercased() {
                    let latinScore = self.calculateSimilarity(between: normalizedText, and: latinName)
                    if latinScore > bestScore && latinScore > 0.7 {
                        bestScore = latinScore
                        bestMatch = structure
                    }
                }
                
                // Verificar sinónimos
                if let synonyms = structure.synonyms {
                    for synonym in synonyms {
                        let synonymScore = self.calculateSimilarity(between: normalizedText, and: synonym.lowercased())
                        if synonymScore > bestScore && synonymScore > 0.7 {
                            bestScore = synonymScore
                            bestMatch = structure
                        }
                    }
                }
            }
            
            mappings.append((text, bestMatch))
        }
        
        return mappings
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