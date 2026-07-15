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
    /// Manual position within its week (drag reorder). Defaults keep capture-date order.
    var sortIndex: Int = 0
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

    static func weekTitle(for weekStart: Date) -> String {
        if weekStart == Self.weekStart(for: .now) {
            return "This week"
        }
        return "Week of \(weekStart.formatted(.dateTime.month(.abbreviated).day()))"
    }

    /// Index for a photo entering a week: in front of everything already there,
    /// without disturbing any manual drag-order the user set.
    static func nextSortIndex(existingInWeek photos: [FoodPhoto]) -> Int {
        (photos.map(\.sortIndex).min() ?? 1) - 1
    }

    /// Stable in-week ordering: manual index first, newest capture as tiebreak.
    static func inWeekOrder(_ a: FoodPhoto, _ b: FoodPhoto) -> Bool {
        if a.sortIndex != b.sortIndex {
            return a.sortIndex < b.sortIndex
        }
        return a.capturedAt > b.capturedAt
    }
}
