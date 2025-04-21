import AppKit
import Foundation

class ImageStore {
    static let shared = ImageStore()
    private let fileManager = FileManager.default
    private let cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 100
    }
    
    func saveImage(_ image: NSImage, withName name: String) throws -> URL {
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentsDirectory.appendingPathComponent(name)
        
        guard let imageData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: imageData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw ImageStoreError.imageConversionFailed
        }
        
        try pngData.write(to: fileURL)
        return fileURL
    }
    
    func loadImage(from url: URL) throws -> NSImage {
        if let cachedImage = cache.object(forKey: url.path as NSString) {
            return cachedImage
        }
        
        let imageData = try Data(contentsOf: url)
        guard let image = NSImage(data: imageData) else {
            throw ImageStoreError.imageLoadFailed
        }
        
        cache.setObject(image, forKey: url.path as NSString)
        return image
    }
    
    func deleteImage(at url: URL) throws {
        try fileManager.removeItem(at: url)
        cache.removeObject(forKey: url.path as NSString)
    }
}

enum ImageStoreError: Error {
    case imageConversionFailed
    case imageLoadFailed
} 