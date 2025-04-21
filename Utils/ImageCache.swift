import AppKit
import Foundation

class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 100
    }
    
    func set(_ image: NSImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func get(forKey key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
} 