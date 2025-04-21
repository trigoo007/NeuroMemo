import Foundation
import Vision
import UIKit
import CoreML

enum SegmentationError: Error {
    case modelLoadFailed
    case processingFailed
    case invalidImage
}

class SegmentationService {
    static let shared = SegmentationService()
    
    private var segmentationModel: VNCoreMLModel?
    
    private init() {
        loadModel()
    }
    
    private func loadModel() {
        // Cargar el modelo de segmentación si está disponible en el bundle
        if let modelURL = Bundle.main.url(forResource: "AnatomicalSegmenter", withExtension: "mlmodelc") {
            do {
                segmentationModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
                print("Modelo de segmentación cargado correctamente")
            } catch {
                print("Error al cargar el modelo de segmentación: \(error.localizedDescription)")
            }
        } else {
            print("Advertencia: No se encontró el modelo de segmentación en el bundle")
        }
    }
    
    /// Segmenta una imagen anatómica e identifica diferentes estructuras
    /// - Parameters:
    ///   - image: UIImage que contiene la imagen anatómica a procesar
    ///   - completion: Callback con el resultado de la segmentación (máscara por estructura)
    func segmentImage(_ image: UIImage, completion: @escaping (Result<[String: UIImage], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(SegmentationError.invalidImage))
            return
        }
        
        guard let model = segmentationModel else {
            completion(.failure(SegmentationError.modelLoadFailed))
            return
        }
        
        // Configurar la solicitud de Vision para la segmentación
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let segmentationMap = results.first?.featureValue.multiArrayValue else {
                completion(.failure(SegmentationError.processingFailed))
                return
            }
            
            // Procesar el mapa de segmentación y convertirlo en máscaras por estructura
            self.processSegmentationMap(segmentationMap, originalImage: image) { result in
                completion(result)
            }
        }
        
        // Configurar opciones de procesamiento
        request.imageCropAndScaleOption = .scaleFill
        
        // Ejecutar la solicitud de Vision
        let handler = VNImageRequestHandler(cgImage: cgImage)
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Procesa el mapa de segmentación producido por el modelo y crea máscaras individuales
    private func processSegmentationMap(_ segmentationMap: MLMultiArray, originalImage: UIImage, completion: @escaping (Result<[String: UIImage], Error>) -> Void) {
        // En una implementación real, convertiríamos el MLMultiArray a múltiples máscaras
        // Aquí proporcionamos un ejemplo simplificado
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Obtener dimensiones del mapa de segmentación
                // Típicamente en forma [batch, clases, altura, anchura]
                let width = segmentationMap.shape[3].intValue
                let height = segmentationMap.shape[2].intValue
                let numClasses = segmentationMap.shape[1].intValue
                
                // Crear diccionario para las máscaras resultantes
                var segmentationMasks: [String: UIImage] = [:]
                
                // Nombres de las clases/estructuras (deberían venir del modelo)
                let classNames = ["fondo", "cerebro", "cerebelo", "tallo_cerebral", "ventrículos", "médula_espinal"]
                
                // Para cada clase, crear una máscara
                for classIndex in 0..<min(numClasses, classNames.count) {
                    let className = classNames[classIndex]
                    
                    // Crear un bitmap para esta clase
                    var pixelBuffer = [UInt8](repeating: 0, count: width * height * 4) // RGBA
                    
                    // Llenar el buffer con los valores de segmentación
                    for y in 0..<height {
                        for x in 0..<width {
                            // Calcular el valor de probabilidad para esta clase en este píxel
                            // El índice exacto dependerá de la estructura del MLMultiArray
                            let index = [0, classIndex, y, x] as [NSNumber]
                            let probability = segmentationMap[index].floatValue
                            
                            // Si la probabilidad supera un umbral, marcar como parte de esta estructura
                            if probability > 0.5 {
                                let pixelIndex = (y * width + x) * 4
                                
                                // Codificar color según la clase (podría usar colores más distintivos)
                                pixelBuffer[pixelIndex] = UInt8(255) // R
                                pixelBuffer[pixelIndex + 1] = UInt8(classIndex * 40) // G
                                pixelBuffer[pixelIndex + 2] = UInt8(255 - classIndex * 40) // B
                                pixelBuffer[pixelIndex + 3] = UInt8(180) // Alpha (semi-transparente)
                            }
                        }
                    }
                    
                    // Convertir el buffer a UIImage
                    let mask = self.createImageFromPixelBuffer(pixelBuffer, width: width, height: height)
                    segmentationMasks[className] = mask
                }
                
                DispatchQueue.main.async {
                    completion(.success(segmentationMasks))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Crea una UIImage a partir de un buffer de píxeles RGBA
    private func createImageFromPixelBuffer(_ pixelBuffer: [UInt8], width: Int, height: Int) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: UnsafeMutableRawPointer(mutating: pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        guard let cgImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Identifica estructuras anatómicas en una región específica de una imagen
    func identifyStructuresInRegion(image: UIImage, region: CGRect, completion: @escaping ([AnatomicalStructure]) -> Void) {
        // En una implementación real, esto combinaría la segmentación con una búsqueda
        // en la base de conocimiento para identificar las estructuras en la región seleccionada
        
        // Primero segmentamos la imagen completa
        segmentImage(image) { result in
            switch result {
            case .success(let segmentationMasks):
                // Buscar qué estructuras están presentes en la región seleccionada
                var detectedStructureIds: [String] = []
                
                // Analizar cada máscara para ver si hay solapamiento con la región
                for (structureName, _) in segmentationMasks {
                    // Aquí habría que comprobar realmente si la máscara tiene píxeles
                    // en la región seleccionada. Simplificamos para el ejemplo.
                    detectedStructureIds.append(structureName)
                }
                
                // Buscar las estructuras correspondientes en la base de conocimiento
                let structures = detectedStructureIds.compactMap { structureId in
                    KnowledgeBase.shared.getStructureById(structureId)
                }
                
                completion(structures)
                
            case .failure:
                // En caso de error, devolver una lista vacía
                completion([])
            }
        }
    }
}