// OCRService.swift
import Foundation
import Vision
import VisionKit
import UIKit

enum OCRServiceError: Error {
    case processingError
    case noTextFound
    case imageConversionError
}

class OCRService {
    // Función principal para extraer texto de una imagen
    func extractText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRServiceError.imageConversionError))
            return
        }
        
        // Crear solicitud de reconocimiento de texto
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRServiceError.processingError))
                return
            }
            
            // Procesar resultados
            let recognizedText = self.processTextObservations(observations)
            
            if recognizedText.isEmpty {
                completion(.failure(OCRServiceError.noTextFound))
            } else {
                completion(.success(recognizedText))
            }
        }
        
        // Configurar solicitud
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["es-ES", "en-US", "la"]
        
        // Ejecutar solicitud
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
    
    // Procesar las observaciones de texto
    private func processTextObservations(_ observations: [VNRecognizedTextObservation]) -> String {
        var recognizedText = ""
        
        for observation in observations {
            if let topCandidate = observation.topCandidates(1).first {
                recognizedText += topCandidate.string + "\n"
            }
        }
        
        return recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Buscar etiquetas en una imagen anatómica
    func findLabels(in image: UIImage, completion: @escaping (Result<[AnatomicalImage.Label], Error>) -> Void) {
        extractText(from: image) { result in
            switch result {
            case .success(let text):
                // Procesar texto para identificar posibles etiquetas
                let labels = self.identifyLabels(text: text, in: image)
                completion(.success(labels))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Identificar posibles etiquetas anatómicas en el texto reconocido
    private func identifyLabels(text: String, in image: UIImage) -> [AnatomicalImage.Label] {
        var labels: [AnatomicalImage.Label] = []
        
        // Dividir texto en líneas
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() where !line.isEmpty {
            // Limpiar texto
            let cleanText = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Crear etiqueta
            let label = AnatomicalImage.Label(
                id: "\(index)",
                text: cleanText,
                position: estimatePositionForLine(index: index, totalLines: lines.count)
            )
            
            labels.append(label)
        }
        
        return labels
    }
    
    // Estimar posición de la etiqueta basándose en su posición en el texto
    // Esta es una implementación simplificada - en una app real se usaría Vision para obtener las coordenadas
    private func estimatePositionForLine(index: Int, totalLines: Int) -> CGPoint {
        // Simulación simple de posiciones
        let x = CGFloat(0.1 + (Double(index % 3) * 0.3))
        let y = CGFloat(0.1 + (Double(index) / Double(max(totalLines, 1)) * 0.8))
        
        return CGPoint(x: x, y: y)
    }
    
    // Función auxiliar para extraer texto de un PDF o documento escaneado
    func extractTextFromDocument(_ document: VNDocumentCameraScan, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var fullText = ""
            
            for pageIndex in 0..<document.pageCount {
                let image = document.image(at: pageIndex)
                
                // Crear un semáforo para esperar por el resultado de cada página
                let semaphore = DispatchSemaphore(value: 0)
                var pageText = ""
                var pageError: Error?
                
                self.extractText(from: image) { result in
                    switch result {
                    case .success(let text):
                        pageText = text
                    case .failure(let error):
                        pageError = error
                    }
                    semaphore.signal()
                }
                
                semaphore.wait()
                
                if let error = pageError {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                fullText += pageText + "\n\n"
            }
            
            DispatchQueue.main.async {
                completion(.success(fullText))
            }
        }
    }
}
