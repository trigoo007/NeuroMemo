import AppKit
import Foundation

class ImageLoader: ObservableObject {
    @Published var image: NSImage?
    private var dataTask: URLSessionDataTask?
    
    func load(from url: URL) {
        if let cachedImage = ImageCache.shared.get(forKey: url.absoluteString) {
            self.image = cachedImage
            return
        }
        
        dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let image = NSImage(data: data) else {
                return
            }
            
            DispatchQueue.main.async {
                self.image = image
                ImageCache.shared.set(image, forKey: url.absoluteString)
            }
        }
        dataTask?.resume()
    }
    
    func cancel() {
        dataTask?.cancel()
    }
} 