import SwiftUI

enum AppColors {
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    // Shared ShopSwift brand colors mirror the browser storefront without
    // coupling native views to CSS or web-only assets.
    static let accent = Color(red: 0.39, green: 0.27, blue: 0.94)
    static let accentDark = Color(red: 0.30, green: 0.18, blue: 0.82)
    static let accentSoft = Color(red: 0.94, green: 0.92, blue: 1.00)
}
