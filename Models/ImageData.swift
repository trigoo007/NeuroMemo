import AppKit
import Foundation

struct ImageData: Codable, Identifiable {
    let id: String
    let url: URL
    let thumbnailURL: URL
    let metadata: ImageMetadata
    var image: NSImage?
    
    struct ImageMetadata: Codable {
        let width: Int
        let height: Int
        let format: String
        let size: Int
        let createdAt: Date
    }
    
    init(id: String = UUID().uuidString,
         url: URL,
         thumbnailURL: URL,
         metadata: ImageMetadata,
         image: NSImage? = nil) {
        self.id = id
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.metadata = metadata
        self.image = image
    }
} 