import Foundation
import UIKit

enum PhotoStoreError: Error {
    case jpegEncodingFailed
}

/// Writes photo files to Application Support/Photos with an in-memory cache.
/// Pure file I/O — metadata is SwiftData's job (`FoodPhoto`).
struct PhotoStore {
    static let shared = PhotoStore()

    private let directory: URL
    private let cache = NSCache<NSString, UIImage>()

    init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("Photos", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Saves a JPEG for the given photo id and returns its file name.
    func save(_ image: UIImage, id: UUID) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw PhotoStoreError.jpegEncodingFailed
        }
        let fileName = "\(id.uuidString).jpg"
        try data.write(to: url(for: fileName), options: .atomic)
        cache.setObject(image, forKey: fileName as NSString)
        return fileName
    }

    /// Cache-first async load; disk read + JPEG decode happen off the caller's actor.
    func loadImage(for fileName: String) async -> UIImage? {
        if let cached = cache.object(forKey: fileName as NSString) {
            return cached
        }

        let path = url(for: fileName).path
        let image = await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: path)
        }.value

        if let image {
            cache.setObject(image, forKey: fileName as NSString)
        }
        return image
    }

    func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    func delete(_ fileName: String) {
        cache.removeObject(forKey: fileName as NSString)
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
