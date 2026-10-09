import SwiftUI

/// Gabay design tokens (design/gabay_v2/Gabay System.dc.html). The extension's CSS mirrors these.
enum Theme {
    // Ring: systemPurple by default; Pink / Orange are options. No blue (reads as system selection).
    static var ring = Color(hex: 0xAF52DE)
    static let ringDark = Color(hex: 0xBF5AF2)
    static let ringChoices: [String: UInt32] = ["Purple": 0xAF52DE, "Pink": 0xE0457B, "Orange": 0xF08A24]
    static let success = Color(hex: 0x2FA35A)
    static let warning = Color(hex: 0xC27A00)
    static let warningSurface = Color(hex: 0xFFF6E4)
    static let secondLine = Color(hex: 0x3A3A3C)

    // Back-compat names used around the app.
    static var beacon: Color { ring }
    static let done = Color(hex: 0x2FA35A)
    static let ink = Color.primary
    static let inkSoft = Color(hex: 0x3A3A3C)
    static let doneText = Color(hex: 0x1F7A41)
    static let detour = Color(hex: 0x8A4300)
    static let beaconInk = Color.primary

    // Geometry
    static let cardRadius: CGFloat = 18
    static let cardMaxWidth: CGFloat = 440
    static let ringPad: CGFloat = 4
    static let gap: CGFloat = 20          // card ↔ ring
    static let cardWidth: CGFloat = 440   // legacy name

    /// Text size: Large 1.0, Larger 1.15, Largest 1.38. Nothing in the overlay is smaller than 15pt.
    static var scale: CGFloat = 1.0
    static func sentence() -> Font { .system(size: 26 * scale, weight: .semibold) }
    static func secondary() -> Font { .system(size: 19 * scale) }
    static func button() -> Font { .system(size: 17 * scale, weight: .semibold) }
    static func small() -> Font { .system(size: 15 * scale, weight: .medium) }
    static func askField() -> Font { .system(size: 26 * scale) }
    // Legacy names
    static func instruction() -> Font { sentence() }
    static func hint() -> Font { secondary() }
    static func label() -> Font { small() }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
