import SwiftUI

enum Theme {
    /// Approximation of the app's nav-bar green, sampled from the screen recording.
    static let green = Color(red: 0.40, green: 0.58, blue: 0.33)

    /// Unselected cells: the light green tint of the bordered "Any" button, but opaque
    /// (green blended into the background) so translucent sheets don't show through.
    static let cellFill = Color(UIColor { traits in
        let isDark = traits.userInterfaceStyle == .dark
        let base: CGFloat = isDark ? 0.11 : 1.0
        let amount: CGFloat = isDark ? 0.28 : 0.30
        func mix(_ c: CGFloat) -> CGFloat { base + (c - base) * amount }
        return UIColor(red: mix(0.40), green: mix(0.58), blue: mix(0.33), alpha: 1)
    })
}
