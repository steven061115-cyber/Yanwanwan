import SwiftUI

// MARK: - HoYo Theme Palette (Anime Quest Board)

extension Color {
    nonisolated static let hoyoPink     = Color(hex: "FF6BAB")   // 主色：棉花糖粉
    nonisolated static let hoyoMint     = Color(hex: "39C5BB")   // 副色：初音未来青
    nonisolated static let hoyoYellow   = Color(hex: "FFE082")   // 点缀：游戏金
    nonisolated static let hoyoDark     = Color(hex: "3B2060")   // 轮廓/文字：深紫
    nonisolated static let hoyoBg       = Color(hex: "FFF8FC")   // 背景：奶白粉
    nonisolated static let hoyoLavender = Color(hex: "DDB4F0")   // 薰衣草紫
    nonisolated static let hoyoNavy     = Color(hex: "3B2060")   // 卡片边框/文字：深紫
    nonisolated static let hoyoCardBg   = Color.white            // 卡片内容区背景

    nonisolated init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 200, 200, 200)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Card Press Button Style

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
