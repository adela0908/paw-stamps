import SwiftUI

enum Palette {
    static let paper = Color(red: 1.0, green: 0.965, blue: 0.878)      // #FFF6E0
    static let paper2 = Color(red: 1.0, green: 0.933, blue: 0.761)     // #FFEEC2
    static let ink = Color(red: 0.169, green: 0.129, blue: 0.090)      // #2B2117
    static let red = Color(red: 0.910, green: 0.314, blue: 0.227)      // #E8503A
    static let yellow = Color(red: 1.0, green: 0.773, blue: 0.192)     // #FFC531
    static let blue = Color(red: 0.353, green: 0.694, blue: 0.910)     // #5AB1E8
    static let pink = Color(red: 1.0, green: 0.561, blue: 0.639)       // #FF8FA3
    static let green = Color(red: 0.482, green: 0.788, blue: 0.435)    // #7BC96F
    static let tan = Color(red: 0.541, green: 0.478, blue: 0.369)      // muted label
    static let faint = Color(red: 0.851, green: 0.788, blue: 0.651)    // dashed rings
    static let disabled = Color(red: 0.847, green: 0.808, blue: 0.722)
}

extension Font {
    static func chunky(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Chunky "sticker" card: white fill, thick ink border, hard offset shadow.
struct StickerCard: ViewModifier {
    var fill: Color = .white
    var corner: CGFloat = 22
    var border: CGFloat = 3.5
    var drop: CGFloat = 5

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(Palette.ink)
                        .offset(y: drop)
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(fill)
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(Palette.ink, lineWidth: border)
                }
            )
    }
}

extension View {
    func stickerCard(fill: Color = .white, corner: CGFloat = 22,
                     border: CGFloat = 3.5, drop: CGFloat = 5) -> some View {
        modifier(StickerCard(fill: fill, corner: corner, border: border, drop: drop))
    }
}

/// Chunky pressable button: moves down onto its own hard shadow when pressed.
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color
    var textColor: Color = .white
    var corner: CGFloat = 18
    var drop: CGFloat = 5

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .foregroundColor(textColor)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(fill)
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(Palette.ink, lineWidth: 3)
                }
            )
            .offset(y: pressed ? drop - 1 : 0)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Palette.ink)
                    .offset(y: drop)
            )
            .padding(.bottom, drop)
            .contentShape(Rectangle())
    }
}
