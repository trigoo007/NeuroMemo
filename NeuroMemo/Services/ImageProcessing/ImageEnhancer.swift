import Foundation
import UIKit
import CoreImage

/// Servicio para mejorar la calidad de imágenes médicas
class ImageEnhancementService {
    // Opciones de mejora
    struct EnhancementOptions {
        var contrastAdjustment: Float = 1.2
        var brightnessAdjustment: Float = 0.0
        var sharpnessAdjustment: Float = 1.3
        var noiseReduction: Float = 0.5
        var adaptiveContrast: Bool = true
    }
    
    // Mejorar imagen con opciones personalizadas
    func enhanceImage(_ image: UIImage, options: EnhancementOptions = EnhancementOptions()) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw ImageProcessingError.invalidImage
        }
        
        // Crear contexto CIImage para procesamiento
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)
        
        // Aplicar filtros en secuencia
        var processedImage = ciImage
        
        // 1. Reducción de ruido
        if options.noiseReduction > 0 {
            if let noiseReductionFilter = CIFilter(name: "CINoiseReduction") {
                noiseReductionFilter.setValue(processedImage, forKey: kCIInputImageKey)
                noiseReductionFilter.setValue(options.noiseReduction, forKey: "inputNoiseLevel")
                noiseReductionFilter.setValue(options.noiseReduction * 0.7, forKey: "inputSharpness")
                
                if let outputImage = noiseReductionFilter.outputImage {
                    processedImage = outputImage
                }
            }
        }
        
        // 2. Ajuste de contraste
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(processedImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(options.contrastAdjustment, forKey: kCIInputContrastKey)
            contrastFilter.setValue(options.brightnessAdjustment, forKey: kCIInputBrightnessKey)
            
            if let outputImage = contrastFilter.outputImage {
                processedImage = outputImage
            }
        }
        
        // 3. Ajuste de nitidez
        if options.sharpnessAdjustment > 1.0 {
            if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
                sharpenFilter.setValue(processedImage, forKey: kCIInputImageKey)
                sharpenFilter.setValue(options.sharpnessAdjustment, forKey: kCIInputSharpnessKey)
                
                if let outputImage = sharpenFilter.outputImage {
                    processedImage = outputImage
                }
            }
        }
        
        // Renderizar resultado final
        guard let outputCGImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            throw ImageProcessingError.processingFailed
        }
        
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // Optimizar imagen para modalidad específica
    func optimizeForModalityType(_ image: UIImage, modality: ImageModality) throws -> UIImage {
        var options = EnhancementOptions()
        
        switch modality {
        case .mri:
            options.contrastAdjustment = 1.3
            options.sharpnessAdjustment = 1.2
            options.noiseReduction = 0.6
        case .ct:
            options.contrastAdjustment = 1.4
            options.brightnessAdjustment = 0.05
            options.sharpnessAdjustment = 1.1
        case .illustration, .diagram:
            options.contrastAdjustment = 1.2
            options.sharpnessAdjustment = 1.4
            options.noiseReduction = 0.2
        default:
            // Valores equilibrados para otros casos
            options.contrastAdjustment = 1.2
            options.sharpnessAdjustment = 1.2
        }
        
        return try enhanceImage(image, options: options)
    }
}

/// Errores de procesamiento de imágenes
enum ImageProcessingError: Error {
    case invalidImage
    case processingFailed
    case enhancementFailed
    case ocrFailed
    case segmentationFailed
}
