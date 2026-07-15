import SwiftUI

/// SaVur design tokens.
/// Placeholder values — swap once Matthew's palette references and logo arrive.
enum Theme {
    // MARK: - Colors (cream / white / brown / blue / red)

    /// Cream app background (#FAF6EF).
    static let cream = Color(red: 0.980, green: 0.965, blue: 0.937)

    /// Card / sheet surfaces.
    static let surface = Color.white

    /// Warm brown primary text (#3E2E20).
    static let ink = Color(red: 0.243, green: 0.180, blue: 0.125)

    /// Secondary text.
    static let inkSoft = ink.opacity(0.55)

    /// Muted slate blue accent.
    static let accentBlue = Color(red: 0.290, green: 0.420, blue: 0.580)

    /// Tomato red accent.
    static let accentRed = Color(red: 0.760, green: 0.300, blue: 0.240)

    // MARK: - Metrics

    static let cornerRadius: CGFloat = 18
    static let stripPhotoSize = CGSize(width: 132, height: 176)
}
