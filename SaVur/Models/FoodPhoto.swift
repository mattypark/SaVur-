import Foundation
import SwiftData

/// One captured or imported photo of organic food.
/// Image bytes live on disk via `PhotoStore`; SwiftData holds metadata only.
@Model
final class FoodPhoto {
    enum Source: String {
        case camera
        case library
    }

    @Attribute(.unique) var id: UUID
    var capturedAt: Date
    /// Start of the week this photo belongs to — the core Retro-style bucket.
    var weekStart: Date
    var fileName: String
    private var sourceRaw: String

    var source: Source {
        Source(rawValue: sourceRaw) ?? .library
    }

    init(id: UUID = UUID(), capturedAt: Date = .now, fileName: String, source: Source) {
        self.id = id
        self.capturedAt = capturedAt
        self.weekStart = Self.weekStart(for: capturedAt)
        self.fileName = fileName
        self.sourceRaw = source.rawValue
    }

    static func weekStart(for date: Date) -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
}
