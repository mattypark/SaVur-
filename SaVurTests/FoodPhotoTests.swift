import XCTest
@testable import SaVur

final class FoodPhotoTests: XCTestCase {
    private let calendar = Calendar.current

    // MARK: - weekStart

    func testWeekStartIsStableWithinOneWeek() {
        // Arrange
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: .now)!
        let early = weekInterval.start.addingTimeInterval(60)
        let late = weekInterval.end.addingTimeInterval(-60)

        // Act + Assert
        XCTAssertEqual(FoodPhoto.weekStart(for: early), FoodPhoto.weekStart(for: late))
    }

    func testWeekStartDiffersAcrossWeeks() {
        // Arrange
        let now = Date.now
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!

        // Act + Assert
        XCTAssertNotEqual(FoodPhoto.weekStart(for: now), FoodPhoto.weekStart(for: lastWeek))
    }

    func testInitBucketsPhotoIntoCaptureWeek() {
        // Arrange
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: .now)!

        // Act
        let photo = FoodPhoto(capturedAt: lastWeek, fileName: "a.jpg", source: .library)

        // Assert
        XCTAssertEqual(photo.weekStart, FoodPhoto.weekStart(for: lastWeek))
    }

    // MARK: - weekTitle

    func testWeekTitleForCurrentWeekIsThisWeek() {
        XCTAssertEqual(FoodPhoto.weekTitle(for: FoodPhoto.weekStart(for: .now)), "This week")
    }

    func testWeekTitleForPastWeekUsesWeekOfPrefix() {
        // Arrange
        let lastWeekStart = FoodPhoto.weekStart(for: calendar.date(byAdding: .weekOfYear, value: -1, to: .now)!)

        // Act + Assert
        XCTAssertTrue(FoodPhoto.weekTitle(for: lastWeekStart).hasPrefix("Week of "))
    }

    // MARK: - nextSortIndex

    func testNextSortIndexPutsNewPhotoInFrontOfReorderedWeek() {
        // Arrange — user manually ordered a week as 0, 1, 2
        let week = (0..<3).map { index -> FoodPhoto in
            let photo = FoodPhoto(capturedAt: .now, fileName: "\(index).jpg", source: .camera)
            photo.sortIndex = index
            return photo
        }

        // Act
        let newIndex = FoodPhoto.nextSortIndex(existingInWeek: week)

        // Assert — new photo outranks the front slot without touching the others
        XCTAssertEqual(newIndex, -1)
        let newcomer = FoodPhoto(capturedAt: .now, fileName: "new.jpg", source: .camera)
        newcomer.sortIndex = newIndex
        let ordered = (week + [newcomer]).sorted(by: FoodPhoto.inWeekOrder)
        XCTAssertEqual(ordered.first?.fileName, "new.jpg")
        XCTAssertEqual(ordered.dropFirst().map(\.fileName), ["0.jpg", "1.jpg", "2.jpg"])
    }

    func testNextSortIndexForEmptyWeekIsZero() {
        XCTAssertEqual(FoodPhoto.nextSortIndex(existingInWeek: []), 0)
    }

    // MARK: - inWeekOrder

    func testInWeekOrderPrefersSortIndex() {
        // Arrange
        let first = FoodPhoto(capturedAt: .now, fileName: "a.jpg", source: .camera)
        let second = FoodPhoto(capturedAt: .now.addingTimeInterval(100), fileName: "b.jpg", source: .camera)
        first.sortIndex = 0
        second.sortIndex = 1

        // Act + Assert
        XCTAssertTrue(FoodPhoto.inWeekOrder(first, second))
        XCTAssertFalse(FoodPhoto.inWeekOrder(second, first))
    }

    func testInWeekOrderFallsBackToNewestFirst() {
        // Arrange — equal sortIndex, different capture times
        let older = FoodPhoto(capturedAt: .now.addingTimeInterval(-100), fileName: "a.jpg", source: .camera)
        let newer = FoodPhoto(capturedAt: .now, fileName: "b.jpg", source: .camera)

        // Act + Assert
        XCTAssertTrue(FoodPhoto.inWeekOrder(newer, older))
        XCTAssertFalse(FoodPhoto.inWeekOrder(older, newer))
    }
}
