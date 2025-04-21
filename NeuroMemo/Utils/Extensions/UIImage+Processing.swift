// UIImage+Processing.swift
import UIKit
import Vision
import CoreImage

extension UIImage {
    // Redimensionar imagen
    func resize(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // Recortar imagen
    func crop(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage,
              let croppedCGImage = cgImage.cropping(to: rect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    // Rotar imagen
    func rotate(by degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180
        let size = CGSize(width: self.size.width, height: self.size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: size.width / 2, y: size.height / 2)
        context?.rotate(by: radians)
        context?.translateBy(x: -size.width / 2, y: -size.height / 2)
        
        self.draw(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
    // Aplicar filtro de escala de grises
    func grayscale() -> UIImage? {
        guard let ciImage = CIImage(image: self) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIColorMonochrome")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: kCIInputColorKey)
        filter?.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter?.outputImage else {
            return nil
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    // Ajustar brillo y contraste
    func adjustBrightnessContrast(brightness: CGFloat, contrast: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: self) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        
        guard let outputImage = filter?.outputImage else {
            return nil
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    // Detectar texto en la imagen
    func detectText(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let cgImage = self.cgImage else {
            completion(.failure(NSError(domain: "UIImage+Processing", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener CGImage"])))
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.success([]))
                return
            }
            
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            completion(.success(text))
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
    
    // Detectar rectángulos en la imagen
    func detectRectangles(completion: @escaping (Result<[CGRect], Error>) -> Void) {
        guard let cgImage = self.cgImage else {
            completion(.failure(NSError(domain: "UIImage+Processing", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener CGImage"])))
            return
        }
        
        let request = VNDetectRectanglesRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRectangleObservation] else {
                completion(.success([]))
                return
            }
            
            let rects = observations.map { observation -> CGRect in
                let topLeft = observation.topLeft
                let topRight = observation.topRight
                let bottomLeft = observation.bottomLeft
                let bottomRight = observation.bottomRight
                
                // Convertir a coordenadas de UIKit
                let minX = min(topLeft.x, bottomLeft.x) * self.size.width
                let maxX = max(topRight.x, bottomRight.x) * self.size.width
                let minY = min(topLeft.y, topRight.y) * self.size.height
                let maxY = max(bottomLeft.y, bottomRight.y) * self.size.height
                
                return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            }
            
            completion(.success(rects))
        }
        
        request.minimumAspectRatio = VNAspectRatio(0.2)
        request.maximumAspectRatio = VNAspectRatio(1.0)
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
    
    // Aplicar filtro de mejora de bordes
    func enhanceEdges() -> UIImage? {
        guard let ciImage = CIImage(image: self) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIEdges")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(2.0, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter?.outputImage else {
            return nil
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    // Combinar con otra imagen
    func blend(with image: UIImage, alpha: CGFloat) -> UIImage? {
        let size = CGSize(width: max(self.size.width, image.size.width),
                         height: max(self.size.height, image.size.height))
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: self.size))
        image.draw(in: CGRect(origin: .zero, size: image.size), blendMode: .normal, alpha: alpha)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
