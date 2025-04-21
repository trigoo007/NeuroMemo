import Foundation
import UIKit
import CoreImage
import Vision

class ImageEnhancer {
    static let shared = ImageEnhancer()
    
    private let context: CIContext
    
    private init() {
        self.context = CIContext()
    }
    
    /// Mejora la calidad de una imagen anatómica para facilitar su estudio
    /// - Parameters:
    ///   - image: Imagen original a mejorar
    ///   - options: Opciones de mejora
    ///   - completion: Callback con la imagen mejorada
    func enhanceAnatomicalImage(_ image: UIImage, options: EnhancementOptions = .default, completion: @escaping (UIImage) -> Void) {
        // Proceso en background para no bloquear la UI
        DispatchQueue.global(qos: .userInitiated).async {
            guard let ciImage = CIImage(image: image) else {
                DispatchQueue.main.async {
                    completion(image) // Devolver imagen original si hay error
                }
                return
            }
            
            // Aplicar filtros según las opciones seleccionadas
            var processedImage = ciImage
            
            if options.contains(.contrast) {
                processedImage = self.adjustContrast(processedImage, amount: options.contrastAmount)
            }
            
            if options.contains(.sharpness) {
                processedImage = self.sharpenImage(processedImage, amount: options.sharpnessAmount)
            }
            
            if options.contains(.noise) {
                processedImage = self.reduceNoise(processedImage, amount: options.noiseReductionAmount)
            }
            
            if options.contains(.edges) {
                processedImage = self.enhanceEdges(processedImage, amount: options.edgeEnhancementAmount)
            }
            
            if options.contains(.colorCorrection) {
                processedImage = self.correctColors(processedImage)
            }
            
            // Convertir de vuelta a UIImage
            if let cgImage = self.context.createCGImage(processedImage, from: processedImage.extent) {
                let enhancedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
                
                DispatchQueue.main.async {
                    completion(enhancedImage)
                }
            } else {
                DispatchQueue.main.async {
                    completion(image) // Devolver imagen original si hay error
                }
            }
        }
    }
    
    /// Ajusta el contraste de la imagen
    private func adjustContrast(_ image: CIImage, amount: Float) -> CIImage {
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(amount, forKey: kCIInputContrastKey)
        return filter.outputImage ?? image
    }
    
    /// Aumenta la nitidez de la imagen
    private func sharpenImage(_ image: CIImage, amount: Float) -> CIImage {
        let filter = CIFilter(name: "CISharpenLuminance")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(amount, forKey: kCIInputSharpnessKey)
        return filter.outputImage ?? image
    }
    
    /// Reduce el ruido de la imagen
    private func reduceNoise(_ image: CIImage, amount: Float) -> CIImage {
        let filter = CIFilter(name: "CINoiseReduction")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(amount, forKey: "inputNoiseLevel")
        filter.setValue(0.5, forKey: "inputSharpness") // Balance entre ruido y detalle
        return filter.outputImage ?? image
    }
    
    /// Mejora los bordes para destacar estructuras anatómicas
    private func enhanceEdges(_ image: CIImage, amount: Float) -> CIImage {
        let filter = CIFilter(name: "CIUnsharpMask")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(amount * 2.0, forKey: kCIInputRadiusKey)
        filter.setValue(amount, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }
    
    /// Corrige los colores para mejorar la visibilidad
    private func correctColors(_ image: CIImage) -> CIImage {
        // Corrección automática de niveles
        let filter = CIFilter(name: "CIAutoAdjustLevels")!
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
    
    /// Detecta y corrige la orientación de una imagen anatómica
    func correctOrientation(_ image: UIImage, completion: @escaping (UIImage) -> Void) {
        // Utilizamos Vision para analizar la imagen y determinar su orientación
        guard let cgImage = image.cgImage else {
            completion(image)
            return
        }
        
        let request = VNDetectHorizonRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            if let result = request.results?.first {
                // Calcular el ángulo de corrección
                let angle = result.angle
                
                // Aplicar la rotación si es necesaria
                if abs(angle) > 0.05 { // Más de ~3 grados
                    // Crear un contexto gráfico para la rotación
                    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
                    let context = UIGraphicsGetCurrentContext()!
                    
                    // Trasladar y rotar
                    context.translateBy(x: image.size.width / 2, y: image.size.height / 2)
                    context.rotate(by: -angle) // Ángulo negativo para corregir
                    context.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
                    
                    // Dibujar la imagen rotada
                    image.draw(at: CGPoint.zero)
                    
                    // Obtener la imagen resultante
                    let correctedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                    UIGraphicsEndImageContext()
                    
                    completion(correctedImage)
                } else {
                    completion(image) // No se necesita corrección
                }
            } else {
                completion(image)
            }
        } catch {
            completion(image)
            print("Error al detectar horizonte: \(error)")
        }
    }
    
    /// Recorta automáticamente la imagen para centrarse en el contenido anatómico relevante
    func cropToRelevantContent(_ image: UIImage, completion: @escaping (UIImage) -> Void) {
        // Convertir a CIImage para procesamiento
        guard let ciImage = CIImage(image: image) else {
            completion(image)
            return
        }
        
        // Detector de rectángulos para encontrar el área de interés
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 3.0
        request.minimumSize = 0.2 // Al menos 20% del ancho/alto
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([request])
            
            if let observations = request.results, !observations.isEmpty {
                // Encontrar el rectángulo que mejor se ajuste al contenido anatómico
                var bestRect: CGRect = .zero
                var bestConfidence: Float = 0
                
                for observation in observations {
                    let boundingBox = observation.boundingBox
                    
                    // Convertir de coordenadas normalizadas (0-1) a píxeles
                    let rect = CGRect(
                        x: boundingBox.origin.x * image.size.width,
                        y: (1 - boundingBox.origin.y - boundingBox.height) * image.size.height,
                        width: boundingBox.width * image.size.width,
                        height: boundingBox.height * image.size.height
                    )
                    
                    if observation.confidence > bestConfidence {
                        bestRect = rect
                        bestConfidence = observation.confidence
                    }
                }
                
                // Si encontramos un buen rectángulo, recortar la imagen
                if bestConfidence > 0.7 {
                    if let cgImage = image.cgImage?.cropping(to: bestRect) {
                        let croppedImage = UIImage(cgImage: cgImage)
                        completion(croppedImage)
                        return
                    }
                }
            }
            
            // Si no se pudo recortar, usar la imagen original
            completion(image)
            
        } catch {
            completion(image)
            print("Error al detectar área de recorte: \(error)")
        }
    }
}

/// Opciones para la mejora de imágenes
struct EnhancementOptions: OptionSet {
    let rawValue: Int
    
    static let contrast = EnhancementOptions(rawValue: 1 << 0)
    static let sharpness = EnhancementOptions(rawValue: 1 << 1)
    static let noise = EnhancementOptions(rawValue: 1 << 2)
    static let edges = EnhancementOptions(rawValue: 1 << 3)
    static let colorCorrection = EnhancementOptions(rawValue: 1 << 4)
    
    static let `default`: EnhancementOptions = [.contrast, .sharpness, .edges]
    static let all: EnhancementOptions = [.contrast, .sharpness, .noise, .edges, .colorCorrection]
    
    // Valores predeterminados para los parámetros de mejora
    var contrastAmount: Float = 1.2       // 1.0 es normal, > 1.0 aumenta el contraste
    var sharpnessAmount: Float = 0.6      // 0.0 a 1.0, donde 1.0 es máximo
    var noiseReductionAmount: Float = 0.5 // 0.0 a 1.0, donde 1.0 es máxima reducción
    var edgeEnhancementAmount: Float = 0.7 // 0.0 a 1.0, donde 1.0 es máximo realce
}