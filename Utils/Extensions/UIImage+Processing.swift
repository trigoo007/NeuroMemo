import Foundation
import UIKit
import CoreImage
import Vision

extension UIImage {
    /// Redimensiona la imagen a un tamaño específico
    func resize(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Redimensiona la imagen proporcionalmente para que se ajuste dentro de un tamaño máximo
    func resizeToFit(maxSize: CGSize) -> UIImage {
        let aspectWidth = maxSize.width / self.size.width
        let aspectHeight = maxSize.height / self.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let newSize = CGSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio)
        return resize(to: newSize)
    }
    
    /// Recorta la imagen a un rectángulo específico
    func crop(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage,
              let croppedImage = cgImage.cropping(to: rect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    /// Aplica un filtro de mejora básica a la imagen
    func enhance(contrast: Float = 1.2, brightness: Float = 0.1, saturation: Float = 1.1) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return self }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        
        guard let outputCIImage = filter?.outputImage else { return self }
        
        let context = CIContext(options: nil)
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return self
        }
        
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    /// Ajusta el brillo y contraste de la imagen
    func adjustBrightnessAndContrast(brightness: Float, contrast: Float) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return self }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        
        guard let outputCIImage = filter?.outputImage else { return self }
        
        let context = CIContext(options: nil)
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return self
        }
        
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    /// Aumenta la nitidez de la imagen
    func sharpen(amount: Float = 0.5) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return self }
        
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(amount, forKey: kCIInputSharpnessKey)
        
        guard let outputCIImage = filter?.outputImage else { return self }
        
        let context = CIContext(options: nil)
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return self
        }
        
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    /// Aplica reducción de ruido a la imagen
    func reduceNoise(level: Float = 0.02) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return self }
        
        let filter = CIFilter(name: "CINoiseReduction")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(level, forKey: "inputNoiseLevel")
        filter?.setValue(0.4, forKey: "inputSharpness")
        
        guard let outputCIImage = filter?.outputImage else { return self }
        
        let context = CIContext(options: nil)
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return self
        }
        
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    /// Convierte la imagen a escala de grises
    func toGrayscale() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return self }
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputCIImage = filter?.outputImage else { return self }
        
        let context = CIContext(options: nil)
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return self
        }
        
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    /// Realza los bordes de la imagen para destacar estructuras
    func enhanceEdges() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return self }
        
        let filter = CIFilter(name: "CIEdges")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(5.0, forKey: kCIInputIntensityKey)
        
        guard let outputCIImage = filter?.outputImage else { return self }
        
        let context = CIContext(options: nil)
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else {
            return self
        }
        
        return UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    /// Extrae texto de la imagen usando Vision
    func extractText(completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = self.cgImage else {
            completion(.failure(NSError(domain: "UIImage+Processing", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener CGImage"])))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.success(""))
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            completion(.success(recognizedText))
        }
        
        // Configurar para español
        request.recognitionLanguages = ["es", "en"]
        request.recognitionLevel = .accurate
        
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Combina dos imágenes (superponiendo la actual sobre la dada)
    func overlayWith(image: UIImage, alpha: CGFloat = 1.0) -> UIImage? {
        let size = self.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        self.draw(in: CGRect(origin: .zero, size: size))
        
        image.draw(in: CGRect(origin: .zero, size: size), blendMode: .normal, alpha: alpha)
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage
    }
    
    /// Agrega texto a la imagen
    func addText(_ text: String, atPoint point: CGPoint, font: UIFont = .systemFont(ofSize: 24), color: UIColor = .white) -> UIImage {
        let textFontAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0)
        self.draw(at: .zero)
        text.draw(at: point, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// Rota la imagen al ángulo especificado (en radianes)
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        // Trasladar el origen al centro
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: CGFloat(radians))
        
        self.draw(in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    /// Convierte la imagen a un formato de datos con la compresión especificada
    func toJPEGData(compressionQuality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: compressionQuality)
    }
    
    func toPNGData() -> Data? {
        return self.pngData()
    }
}