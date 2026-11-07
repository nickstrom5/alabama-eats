import SwiftUI
import UIKit
import CoreText

/// Alabama palette (provisional, 2026-11-06; Nick decides, playbook/05-naming.md), light only. The Iron Bowl splits the state, so no
/// school's colors: the state flag's crimson #B0202E (6.8:1 on white, 6.0:1 on sand; not the University of Alabama's #9E1B32) for the
/// hand-checked guide cards under white text; Gulf teal #1F5F6B (7.2:1 on white) for titles, tint and accents; a darker crimson #8A1A24
/// for honors chips (white on it 9.3:1); yellowhammer gold #E8B04A only as a fill under coal #1E1E1E (8.5:1), never as text (2:1 on
/// white); sand #F7F1E3 pages. The names `green`/`gold` are kept from Wisconsin Eats so the shared views read the same; here `green`
/// is Gulf teal and `gold` is flag crimson.
enum Theme {
    static let green = Color(hex: 0x1F5F6B)      // Gulf teal: titles, tint, primary text accents
    static let green2 = Color(hex: 0x2E7480)
    static let gold = Color(hex: 0xB0202E)       // flag crimson: card fills under white text
    static let goldSoft = Color(hex: 0xF6DCDD)   // soft crimson
    static let lime = Color(hex: 0xE8B04A)       // yellowhammer gold, fills only (hand-checked pins, the title shadow), under coal
    static let limeSoft = Color(hex: 0xF8E7C2)
    static let sand = Color(hex: 0xF7F1E3)       // the Home background
    static let red = Color(hex: 0x8A1A24)        // dark crimson: honors chips
    static let sandstone = Color(hex: 0xB0202E)  // crimson accent (6.8:1 on white)
    static let teal = Color(hex: 0x1F5F6B)       // Gulf teal accent (7.2:1 on white)
    static let ink = Color(hex: 0x1E1E1E)
    static let ink2 = Color(hex: 0x2E3440)
    static let muted = Color(hex: 0x5B6270)
    static let surface = Color.white
    static let surface2 = Color(hex: 0xF2EDE1)
    static let surface3 = Color(hex: 0xE5DFD1)
    static let rule = Color(hex: 0xE5DFD1)
    static let rule2 = Color(hex: 0xCCC4B3)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// A small uppercase label: "STONE CRAB", "1 MICHELIN STAR".
struct Chip: View {
    enum Style { case gold, green, red, plain, dashed }
    let text: String
    var style: Style = .plain

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .foregroundStyle(style == .green || style == .red ? Color.white : style == .dashed ? Theme.muted : style == .gold ? Theme.ink : Theme.green)
            .background {
                RoundedRectangle(cornerRadius: 5).fill(style == .gold ? Theme.goldSoft : style == .green ? Theme.green : style == .red ? Theme.red
                                                       : style == .dashed ? .clear : Theme.surface2)
            }
            .overlay {
                if style == .dashed { RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.rule2, style: StrokeStyle(lineWidth: 1, dash: [3, 2])) }
            }
            .accessibilityLabel(text)
    }
}

/// Alabama Eats' lettering: the system face drawn compressed and heavy for titles and guide names, and the
/// system monospaced face for numbers, dates and small labels. No bundled fonts.
struct DisplayFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .black
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight).width(.compressed))
    }
}

/// Numbers, dates and small labels in the system monospaced face, scaled like DisplayFont.
struct MonoFont: ViewModifier {
    let size: CGFloat
    var weight: Font.Weight = .semibold
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content.font(.system(size: size * min(scale, 1.6), weight: weight, design: .monospaced))
    }
}

extension View {
    func displayFont(_ size: CGFloat, weight: Font.Weight = .black) -> some View {
        modifier(DisplayFont(size: size, weight: weight))
    }

    func monoFont(_ size: CGFloat, weight: Font.Weight = .semibold) -> some View {
        modifier(MonoFont(size: size, weight: weight))
    }
}

/// The header band: a row of camellias (the state flower) in flag crimson with yellowhammer-gold centers, on a Gulf-teal line.
struct Stripes: View {
    var height: CGFloat = 9

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, line = h * 0.5
            ctx.fill(Path(CGRect(x: 0, y: line - 1.5, width: w, height: 3)), with: .color(Theme.green))
            let r = h * 0.42, n = max(3, Int(w / (r * 4.2)))
            for i in 0..<n {
                let cx = (CGFloat(i) + 0.5) * w / CGFloat(n), cy = line
                for k in 0..<5 {   // five round petals around the center
                    let a = CGFloat(k) * 2 * .pi / 5 - .pi / 2
                    let px = cx + cos(a) * r * 0.52, py = cy + sin(a) * r * 0.52
                    ctx.fill(Path(ellipseIn: CGRect(x: px - r * 0.52, y: py - r * 0.52, width: r * 1.04, height: r * 1.04)), with: .color(Theme.gold))
                }
                ctx.fill(Path(ellipseIn: CGRect(x: cx - r * 0.3, y: cy - r * 0.3, width: r * 0.6, height: r * 0.6)), with: .color(Theme.lime))
            }
        }
        .frame(height: height * 2.4)
        .accessibilityHidden(true)
    }
}

extension View {
    /// An inline navigation title in the display type. UINavigationBar.appearance() didn't reach every SwiftUI bar on iOS 27
    /// (the Map title went from compressed blue to plain black after a push and pop; place titles were always plain), so the
    /// title is our own view in the bar. The navigation title is still set, for the back button and VoiceOver.
    func inlineTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title).displayFont(19, weight: .heavy).foregroundStyle(Theme.green)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                }
            }
    }
}
