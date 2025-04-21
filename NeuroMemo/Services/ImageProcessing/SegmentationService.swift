// SegmentationService.swift
import Foundation
import Vision
import UIKit

enum SegmentationError: Error {
    case processingError
    case noObjectsDetected
    case imageConversionError
}

class SegmentationService {
    // Identificar y segmentar diferentes partes en una imagen anatómica
    func segmentImage(image: UIImage, completion: @escaping (Result<[AnatomicalSegment], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(SegmentationError.imageConversionError))
            return
        }
        
        // Crear solicitud de análisis de imagen
        let request = VNGenerateObjectnessBasedSaliencyImageRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let results = request.results as? [VNSaliencyImageObservation],
                  let observation = results.first else {
                completion(.failure(SegmentationError.processingError))
                return
            }
            
            // Procesar mapa de prominencia para detectar regiones
            self.processRegions(from: observation, in: image, completion: completion)
        }
        
        // Ejecutar solicitud
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
    
    // Procesar regiones detectadas en el mapa de prominencia
    private func processRegions(from observation: VNSaliencyImageObservation, in image: UIImage, completion: @escaping (Result<[AnatomicalSegment], Error>) -> Void) {
        guard let salientObjects = observation.salientObjects else {
            completion(.failure(SegmentationError.noObjectsDetected))
            return
        }
        
        let imageSize = image.size
        var segments: [AnatomicalSegment] = []
        
        for (index, object) in salientObjects.enumerated() {
            // Convertir coordenadas normalizadas a coordenadas de imagen
            let boundingBox = VNImageRectForNormalizedRect(object.boundingBox, Int(imageSize.width), Int(imageSize.height))
            
            // Crear segmento anatómico
            let segment = AnatomicalSegment(
                id: "segment_\(index)",
                boundingBox: boundingBox,
                confidence: object.confidence,
                maskImage: nil
            )
            
            segments.append(segment)
            
            // Si hay muchos segmentos, limitamos para no sobrecargar
            if segments.count >= 10 {
                break
            }
        }
        
        if segments.isEmpty {
            completion(.failure(SegmentationError.noObjectsDetected))
        } else {
            completion(.success(segments))
        }
    }
    
    // Crear máscaras para cada segmento
    func generateMasks(for segments: [AnatomicalSegment], from image: UIImage) -> [AnatomicalSegment] {
        var segmentsWithMasks: [AnatomicalSegment] = []
        
        for segment in segments {
            // Crear una imagen de máscara
            let renderer = UIGraphicsImageRenderer(size: image.size)
            let maskImage = renderer.image { context in
                UIColor.clear.setFill()
                context.fill(CGRect(origin: .zero, size: image.size))
                
                UIColor.white.setFill()
                context.fill(segment.boundingBox)
            }
            
            let segmentWithMask = AnatomicalSegment(
                id: segment.id,
                boundingBox: segment.boundingBox,
                confidence: segment.confidence,
                maskImage: maskImage
            )
            
            segmentsWithMasks.append(segmentWithMask)
        }
        
        return segmentsWithMasks
    }
    
    // Mejorar una región de la imagen
    func enhanceRegion(in image: UIImage, region: CGRect) -> UIImage {
        guard let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: region) else {
            return image
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage)
        
        // Aplicar mejoras (brillo, contraste)
        return applyEnhancements(to: croppedImage)
    }
    
    // Aplicar mejoras básicas a una imagen
    private func applyEnhancements(to image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else {
            return image
        }
        
        // Crear contexto CIImage
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // Ajustar filtros
        guard let filter = CIFilter(name: "CIColorControls") else {
            return image
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.1, forKey: kCIInputContrastKey) // Aumentar contraste
        filter.setValue(0.1, forKey: kCIInputBrightnessKey) // Aumentar brillo ligeramente
        filter.setValue(1.1, forKey: kCIInputSaturationKey) // Aumentar saturación
        
        // Aplicar filtro
        guard let outputImage = filter.outputImage,
              let cgOutputImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgOutputImage)
    }
}

struct AnatomicalSegment {
    let id: String
    let boundingBox: CGRect
    let confidence: Float
    let maskImage: UIImage?
}
