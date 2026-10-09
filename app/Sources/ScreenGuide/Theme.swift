import SwiftUI

/// Design A "Liquid Glass" tokens from design/handoff/design_handoff_beside/README.md.
enum Theme {
    static let beacon = Color(hex: 0xF08A24)        // ring, mark, mic
    static let beaconInk = Color(hex: 0xB85A00)     // key word on light
    static let beaconInkDark = Color(hex: 0xFFB066)
    static let detour = Color(hex: 0x8A4300)
    static let done = Color(hex: 0x2FA35A)
    static let doneText = Color(hex: 0x1F7A41)
    static let ink = Color(hex: 0x1C1C1E)
    static let inkSoft = Color(hex: 0x48484D)
    static let tertiary = Color(hex: 0x6E6E73)

    static let cardRadius: CGFloat = 28
    static let cardWidth: CGFloat = 360
    static let ringPad: CGFloat = 4          // ring hugs the AX frame + 4pt
    static let gap: CGFloat = 12             // card ↔ target

    // Type (SF Pro). Word size scale ×1.0 / 1.2 / 1.4 comes from settings.
    static var scale: CGFloat = 1.0
    static func instruction() -> Font { .system(size: 26 * scale, weight: .semibold) }
    static func hint() -> Font { .system(size: 17 * scale) }
    static func label() -> Font { .system(size: 13 * scale, weight: .bold) }
    static func button() -> Font { .system(size: 16 * scale, weight: .semibold) }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
