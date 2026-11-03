import SwiftUI

/// Colours taken from the gallery wall and Vermeer's own palette.
enum Theme {
    static let wall = dynamic(light: 0xE8E7E1, dark: 0x16181D)
    static let ink = dynamic(light: 0x22252B, dark: 0xEBE9E2)
    static let muted = dynamic(light: 0x5D6068, dark: 0xA3A5AD)
    static let label = dynamic(light: 0xF6F5F1, dark: 0x1F2228)
    static let rule = dynamic(light: 0xCFCDC5, dark: 0x33363E)
    static let ultramarine = dynamic(light: 0x233F9C, dark: 0x8FA6F2)
    static let truth = dynamic(light: 0x2D6A46, dark: 0x6CC290)
    static let falsehood = dynamic(light: 0xA23B2C, dark: 0xEF8A78)
    static let frame = dynamic(light: 0x2B2620, dark: 0x0B0B0D)

    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .serif) }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .monospaced) }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? uiColor(dark) : uiColor(light) })
    }

    private static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }
}
