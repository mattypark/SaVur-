#if DEBUG
import SwiftData
import UIKit

/// Dev-only: launch with `-seedDemo` to fill the journal with placeholder
/// photos across three weeks. Never runs in release builds.
enum DebugSeeder {
    static func seedIfRequested(context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-seedDemo") else { return }

        let existing = (try? context.fetchCount(FetchDescriptor<FoodPhoto>())) ?? 0
        guard existing == 0 else { return }

        let palette: [UIColor] = [
            UIColor(red: 0.72, green: 0.55, blue: 0.35, alpha: 1),  // wood
            UIColor(red: 0.45, green: 0.55, blue: 0.35, alpha: 1),  // greens
            UIColor(red: 0.85, green: 0.72, blue: 0.55, alpha: 1),  // eggs
            UIColor(red: 0.75, green: 0.35, blue: 0.28, alpha: 1),  // tomato
            UIColor(red: 0.55, green: 0.62, blue: 0.70, alpha: 1),  // slate
        ]

        for weekOffset in 0..<3 {
            let photosThisWeek = 3 + weekOffset
            for dayOffset in 0..<photosThisWeek {
                let capturedAt = Calendar.current.date(
                    byAdding: .day,
                    value: -(weekOffset * 7 + dayOffset),
                    to: .now
                ) ?? .now

                let color = palette[(weekOffset + dayOffset) % palette.count]
                let id = UUID()
                guard let fileName = try? PhotoStore.shared.save(placeholderImage(color: color), id: id) else {
                    continue
                }
                context.insert(FoodPhoto(id: id, capturedAt: capturedAt, fileName: fileName, source: .library))
            }
        }
    }

    private static func placeholderImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 400, height: 533)
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
#endif
