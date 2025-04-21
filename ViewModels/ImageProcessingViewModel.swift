import Foundation
import UIKit
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageProcessingViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Float = 0.0
    @Published var originalImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var error: ImageProcessingError?
    
    private var cancellables = Set<AnyCancellable>()
    private let context = CIContext()
    
    // Errores específicos para procesamiento de imágenes
    enum ImageProcessingError: Error, LocalizedError {
        case invalidInput
        case processingFailed(String)
        case lowQuality
        case noFeaturesDetected
        
        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "La imagen no es válida para su procesamiento."
            case .processingFailed(let reason):
                return "Fallo en el procesamiento: \(reason)"
            case .lowQuality:
                return "La calidad de la imagen es demasiado baja para un procesamiento efectivo."
            case .noFeaturesDetected:
                return "No se pudieron detectar características anatómicas en la imagen."
            }
        }
    }
    
    func processImage(_ image: UIImage) {
        guard !isProcessing else { return }
        
        originalImage = image
        processedImage = nil
        error = nil
        isProcessing = true
        progress = 0.1
        
        // Usar DispatchQueue para no bloquear la UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Verificar la calidad de la imagen
                if let qualityIssue = self.checkImageQuality(image) {
                    self.updateProgressAndError(progress: 0, error: qualityIssue)
                    return
                }
                
                // Paso 1: Mejorar el contraste
                self.updateProgress(0.2)
                guard let enhancedImage = try self.enhanceContrast(image) else {
                    self.updateProgressAndError(progress: 0.2, error: .processingFailed("Falló la mejora de contraste"))
                    return
                }
                
                // Paso 2: Reducir ruido
                self.updateProgress(0.4)
                guard let denoised = try self.reduceNoise(enhancedImage) else {
                    self.updateProgressAndError(progress: 0.4, error: .processingFailed("Falló la reducción de ruido"))
                    return
                }
                
                // Paso 3: Mejorar bordes
                self.updateProgress(0.6)
                guard let sharpened = try self.enhanceEdges(denoised) else {
                    self.updateProgressAndError(progress: 0.6, error: .processingFailed("Falló la mejora de bordes"))
                    return
                }
                
                // Paso 4: Normalizar colores
                self.updateProgress(0.8)
                guard let final = try self.normalizeColors(sharpened) else {
                    self.updateProgressAndError(progress: 0.8, error: .processingFailed("Falló la normalización de colores"))
                    return
                }
                
                // Finalizar
                self.updateProcessedImage(final)
                
            } catch let processingError as ImageProcessingError {
                self.updateProgressAndError(progress: 0, error: processingError)
            } catch {
                self.updateProgressAndError(
                    progress: 0,
                    error: .processingFailed(error.localizedDescription)
                )
            }
        }
    }
    
    private func updateProgress(_ newProgress: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.progress = newProgress
        }
    }
    
    private func updateProcessedImage(_ image: UIImage) {
        DispatchQueue.main.async { [weak self] in
            self?.processedImage = image
            self?.progress = 1.0
            self?.isProcessing = false
        }
    }
    
    private func updateProgressAndError(progress: Float, error: ImageProcessingError) {
        DispatchQueue.main.async { [weak self] in
            self?.error = error
            self?.progress = progress
            self?.isProcessing = false
        }
    }
    
    // MARK: - Procesamiento de imágenes
    
    private func checkImageQuality(_ image: UIImage) -> ImageProcessingError? {
        // Verificar tamaño mínimo
        if image.size.width < 200 || image.size.height < 200 {
            return .lowQuality
        }
        
        // Podría verificar más factores de calidad aquí
        
        return nil
    }
    
    private func enhanceContrast(_ image: UIImage) throws -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidInput
        }
        
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.contrast = 1.1  // Aumentar contraste ligeramente
        filter.saturation = 1.0
        filter.brightness = 0.05  // Aumentar brillo ligeramente
        
        guard let outputImage = filter.outputImage else {
            throw ImageProcessingError.processingFailed("Falló el filtro de contraste")
        }
        
        return try renderCIImage(outputImage)
    }
    
    private func reduceNoise(_ image: UIImage) throws -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidInput
        }
        
        let filter = CIFilter.noiseReduction()
        filter.inputImage = ciImage
        filter.noiseLevel = 0.02
        filter.sharpness = 0.4
        
        guard let outputImage = filter.outputImage else {
            throw ImageProcessingError.processingFailed("Falló el filtro de reducción de ruido")
        }
        
        return try renderCIImage(outputImage)
    }
    
    private func enhanceEdges(_ image: UIImage) throws -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidInput
        }
        
        let filter = CIFilter.unsharpMask()
        filter.inputImage = ciImage
        filter.radius = 2.5
        filter.intensity = 0.5
        
        guard let outputImage = filter.outputImage else {
            throw ImageProcessingError.processingFailed("Falló el filtro de mejora de bordes")
        }
        
        return try renderCIImage(outputImage)
    }
    
    private func normalizeColors(_ image: UIImage) throws -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            throw ImageProcessingError.invalidInput
        }
        
        // Aplicar un filtro para normalizar histograma de colores
        let filter = CIFilter.photoEffectNoir()
        filter.inputImage = ciImage
        
        guard let outputImage = filter.outputImage else {
            throw ImageProcessingError.processingFailed("Falló el filtro de normalización de colores")
        }
        
        // Crear un filtro de mezcla para controlar la intensidad
        let blendFilter = CIFilter.colorBlendMode()
        blendFilter.inputImage = outputImage
        blendFilter.backgroundImage = ciImage
        
        guard let finalImage = blendFilter.outputImage else {
            throw ImageProcessingError.processingFailed("Falló el filtro de mezcla")
        }
        
        return try renderCIImage(finalImage)
    }
    
    // Función auxiliar para renderizar CIImage a UIImage
    private func renderCIImage(_ ciImage: CIImage) throws -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw ImageProcessingError.processingFailed("No se pudo convertir CIImage a CGImage")
        }
        return UIImage(cgImage: cgImage)
    }
    
    // Limpiar recursos al finalizar
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
} 