import Foundation
import UIKit

class ImageStore {
    static let shared = ImageStore()
    
    private let fileManager = FileManager.default
    private let imageCache = NSCache<NSString, UIImage>()
    
    private init() {
        // Configurar el caché para evitar uso excesivo de memoria
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        
        // Crear directorios necesarios si no existen
        setupDirectories()
    }
    
    // MARK: - Configuración y Gestión
    
    private func setupDirectories() {
        do {
            let imagesURL = try getImagesDirectoryURL()
            try fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true)
            
            let userImagesURL = try getUserImagesDirectoryURL()
            try fileManager.createDirectory(at: userImagesURL, withIntermediateDirectories: true)
        } catch {
            print("Error al configurar directorios de imágenes: \(error)")
        }
    }
    
    private func getImagesDirectoryURL() throws -> URL {
        try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Images", isDirectory: true)
    }
    
    private func getUserImagesDirectoryURL() throws -> URL {
        try getImagesDirectoryURL().appendingPathComponent("User", isDirectory: true)
    }
    
    // MARK: - Almacenamiento y Recuperación
    
    /// Guarda una imagen asociada a una estructura anatómica
    /// - Parameters:
    ///   - image: La imagen a guardar
    ///   - structureId: ID de la estructura anatómica
    ///   - isUserProvided: Si la imagen es proporcionada por el usuario
    ///   - completion: Callback con el resultado (URL de la imagen guardada o error)
    func saveImage(_ image: UIImage, forStructure structureId: String, isUserProvided: Bool = false, completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Determinar directorio según si es del usuario o del sistema
                let baseURL = isUserProvided ? 
                    try self.getUserImagesDirectoryURL() : 
                    try self.getImagesDirectoryURL()
                
                // Crear un identificador único para la imagen
                let imageId = "\(structureId)_\(UUID().uuidString)"
                let imageURL = baseURL.appendingPathComponent("\(imageId).jpg")
                
                // Comprimir la imagen y guardar
                if let imageData = image.jpegData(compressionQuality: 0.85) {
                    try imageData.write(to: imageURL)
                    
                    // Guardar en caché para acceso rápido
                    self.imageCache.setObject(image, forKey: imageURL.path as NSString)
                    
                    // Éxito
                    DispatchQueue.main.async {
                        completion(.success(imageURL))
                    }
                } else {
                    throw NSError(domain: "ImageStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo comprimir la imagen"])
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Carga una imagen desde su URL
    /// - Parameters:
    ///   - url: URL de la imagen a cargar
    ///   - completion: Callback con el resultado (imagen o error)
    func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // Comprobar primero en la caché
        if let cachedImage = imageCache.object(forKey: url.path as NSString) {
            completion(.success(cachedImage))
            return
        }
        
        // Si no está en caché, cargar del sistema de archivos
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                
                if let image = UIImage(data: data) {
                    // Guardar en caché para futuros accesos
                    self.imageCache.setObject(image, forKey: url.path as NSString)
                    
                    DispatchQueue.main.async {
                        completion(.success(image))
                    }
                } else {
                    throw NSError(domain: "ImageStore", code: 3, userInfo: [NSLocalizedDescriptionKey: "No se pudo crear la imagen a partir de los datos"])
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Obtiene todas las imágenes asociadas a una estructura anatómica
    /// - Parameters:
    ///   - structureId: ID de la estructura
    ///   - includeUserImages: Si se deben incluir imágenes proporcionadas por el usuario
    ///   - completion: Callback con la lista de URLs de imágenes
    func getImagesForStructure(_ structureId: String, includeUserImages: Bool = true, completion: @escaping ([URL]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var imageURLs: [URL] = []
            
            do {
                // Obtener imágenes del sistema
                let systemImagesURL = try self.getImagesDirectoryURL()
                let systemContents = try self.fileManager.contentsOfDirectory(at: systemImagesURL, includingPropertiesForKeys: nil)
                
                // Filtrar por ID de estructura
                let systemImages = systemContents.filter { url in
                    url.lastPathComponent.starts(with: "\(structureId)_") && 
                    url.pathExtension.lowercased() == "jpg"
                }
                
                imageURLs.append(contentsOf: systemImages)
                
                // Si se solicitan imágenes del usuario, incluirlas también
                if includeUserImages {
                    let userImagesURL = try self.getUserImagesDirectoryURL()
                    let userContents = try self.fileManager.contentsOfDirectory(at: userImagesURL, includingPropertiesForKeys: nil)
                    
                    let userImages = userContents.filter { url in
                        url.lastPathComponent.starts(with: "\(structureId)_") && 
                        url.pathExtension.lowercased() == "jpg"
                    }
                    
                    imageURLs.append(contentsOf: userImages)
                }
            } catch {
                print("Error al obtener imágenes: \(error)")
                // Continuar con cualquier URL que se haya encontrado hasta ahora
            }
            
            DispatchQueue.main.async {
                completion(imageURLs)
            }
        }
    }
    
    // MARK: - Gestión de Imágenes
    
    /// Elimina una imagen específica
    /// - Parameters:
    ///   - url: URL de la imagen a eliminar
    ///   - completion: Callback con el resultado (éxito o error)
    func deleteImage(at url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Eliminar del sistema de archivos
                try self.fileManager.removeItem(at: url)
                
                // Eliminar de la caché
                self.imageCache.removeObject(forKey: url.path as NSString)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Elimina todas las imágenes asociadas a una estructura
    func deleteAllImagesForStructure(_ structureId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        getImagesForStructure(structureId) { urls in
            let group = DispatchGroup()
            var successCount = 0
            var lastError: Error?
            
            for url in urls {
                group.enter()
                self.deleteImage(at: url) { result in
                    switch result {
                    case .success:
                        successCount += 1
                    case .failure(let error):
                        lastError = error
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if let error = lastError, successCount == 0 {
                    completion(.failure(error))
                } else {
                    completion(.success(successCount))
                }
            }
        }
    }
    
    /// Limpia imágenes en caché para liberar memoria
    func clearCache() {
        imageCache.removeAllObjects()
    }
    
    // MARK: - Procesamiento de Imágenes
    
    /// Guarda una imagen mejorada de una imagen existente
    func saveEnhancedVersion(of originalURL: URL, enhancedImage: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        // Extraer el structureId del nombre de archivo original
        let filename = originalURL.lastPathComponent
        if let structureId = filename.split(separator: "_").first.map(String.init) {
            let isUserProvided = originalURL.path.contains("/User/")
            saveImage(enhancedImage, forStructure: structureId, isUserProvided: isUserProvided, completion: completion)
        } else {
            // Si no se puede determinar el structureId, usar uno genérico
            saveImage(enhancedImage, forStructure: "enhanced", isUserProvided: true, completion: completion)
        }
    }
}