// ImageStore.swift
import Foundation
import UIKit

enum ImageStoreError: Error {
    case saveError
    case loadError
    case deleteError
    case imageNotFound
}

class ImageStore {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Guardar imagen en el almacenamiento local
    func saveImage(_ image: UIImage, withName name: String) -> Result<URL, Error> {
        // Crear directorio si no existe
        let imagesDirectory = documentsDirectory.appendingPathComponent("Images")
        
        do {
            if !fileManager.fileExists(atPath: imagesDirectory.path) {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            }
            
            // Crear URL para la imagen
            let fileName = "\(name)_\(UUID().uuidString).jpg"
            let fileURL = imagesDirectory.appendingPathComponent(fileName)
            
            // Convertir imagen a datos JPEG
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                return .failure(ImageStoreError.saveError)
            }
            
            // Guardar datos en archivo
            try imageData.write(to: fileURL)
            
            return .success(fileURL)
        } catch {
            return .failure(error)
        }
    }
    
    // Cargar imagen desde el almacenamiento local
    func loadImage(from url: URL) -> Result<UIImage, Error> {
        do {
            let imageData = try Data(contentsOf: url)
            
            guard let image = UIImage(data: imageData) else {
                return .failure(ImageStoreError.loadError)
            }
            
            return .success(image)
        } catch {
            return .failure(error)
        }
    }
    
    // Eliminar imagen del almacenamiento local
    func deleteImage(at url: URL) -> Result<Void, Error> {
        do {
            try fileManager.removeItem(at: url)
            return .success(())
        } catch {
            return .failure(ImageStoreError.deleteError)
        }
    }
    
    // Obtener listado de todas las imágenes guardadas
    func getAllImages() -> Result<[URL], Error> {
        let imagesDirectory = documentsDirectory.appendingPathComponent("Images")
        
        // Verificar si el directorio existe
        guard fileManager.fileExists(atPath: imagesDirectory.path) else {
            return .success([])
        }
        
        do {
            // Obtener contenido del directorio
            let directoryContents = try fileManager.contentsOfDirectory(
                at: imagesDirectory,
                includingPropertiesForKeys: nil
            )
            
            // Filtrar sólo archivos de imagen
            let imageFiles = directoryContents.filter { url in
                return url.pathExtension.lowercased() == "jpg" ||
                       url.pathExtension.lowercased() == "jpeg" ||
                       url.pathExtension.lowercased() == "png"
            }
            
            return .success(imageFiles)
        } catch {
            return .failure(error)
        }
    }
    
    // Crear una versión en miniatura de la imagen
    func createThumbnail(from image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // Guardar imagen con sus miniaturas
    func saveImageWithThumbnails(_ image: UIImage, withName name: String) -> Result<(imageURL: URL, thumbnailURL: URL), Error> {
        let thumbnail = createThumbnail(from: image)
        
        // Guardar imagen original
        let saveResult = saveImage(image, withName: name)
        
        guard case .success(let imageURL) = saveResult else {
            if case .failure(let error) = saveResult {
                return .failure(error)
            }
            return .failure(ImageStoreError.saveError)
        }
        
        // Guardar miniatura
        let saveThumbResult = saveImage(thumbnail, withName: "\(name)_thumb")
        
        guard case .success(let thumbnailURL) = saveThumbResult else {
            // Si falla la miniatura, eliminar la imagen original
            _ = deleteImage(at: imageURL)
            
            if case .failure(let error) = saveThumbResult {
                return .failure(error)
            }
            return .failure(ImageStoreError.saveError)
        }
        
        return .success((imageURL: imageURL, thumbnailURL: thumbnailURL))
    }
}
