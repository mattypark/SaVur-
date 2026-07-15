import Foundation
import ImageIO

/// Reads EXIF metadata so imported photos land in the week they were taken —
/// Retro-style retroactive backfill without asking for photo-library permission.
enum ImageMetadata {
    // NOTE: DateFormatter is not thread-safe. Only touched from the @MainActor
    // import loop today — make this a per-call local if parsing is ever parallelized.
    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()

    static func captureDate(from data: Data) -> Date? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
            let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String
        else {
            return nil
        }
        return exifDateFormatter.date(from: dateString)
    }
}
