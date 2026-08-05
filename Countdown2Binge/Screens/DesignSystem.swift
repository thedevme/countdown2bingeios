import SwiftUI

// MARK: - Color Theme
extension Color {
    // Initialize Color from hex string - MUST come first!
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Color constants - now these can use init(hex:) above
    static let c2bBackground = Color(hex: "#000000")
    static let c2bSurface = Color(hex: "#0d0d0e")
    static let c2bSurface2 = Color(hex: "#161618")

    static let c2bText = Color(hex: "#f4f4f5")
    static let c2bDim = Color(hex: "#a1a1aa")
    static let c2bMuted = Color(hex: "#71717a")

    static let c2bTeal = Color(hex: "#2dd4bf")
    static let c2bTealBright = Color(hex: "#5eead4")
    static let c2bTealLine = Color(hex: "#2dd4bf").opacity(0.40)

    // Pending/Warning colors (yellow/amber)
    static let c2bYellow = Color(hex: "#eab308")
    static let c2bYellowBright = Color(hex: "#facc15")
    static let c2bYellowLine = Color(hex: "#eab308").opacity(0.40)
}

// MARK: - Typography
enum CustomFont: String {
    case oswaldBold = "Oswald-Bold"
    case oswaldRegular = "Oswald-Regular"
    case oswaldMedium = "Oswald-Medium"
    case oswaldLight = "Oswald-Light"

    case jetBrainsBold = "JetBrainsMono-Bold"
    case jetBrainsRegular = "JetBrainsMono-Regular"
    case jetBrainsMedium = "JetBrainsMono-Medium"

    enum oswald {
        static let bold = CustomFont.oswaldBold
        static let regular = CustomFont.oswaldRegular
        static let medium = CustomFont.oswaldMedium
        static let light = CustomFont.oswaldLight
    }

    enum jetbrains {
        static let bold = CustomFont.jetBrainsBold
        static let regular = CustomFont.jetBrainsRegular
        static let medium = CustomFont.jetBrainsMedium
    }

    // Scalable size system
    enum size {
        static let xs: CGFloat = 7      // Extra small
        static let sm: CGFloat = 9      // Small
        static let base: CGFloat = 10   // Base
        static let md: CGFloat = 13     // Medium
        static let lg: CGFloat = 15     // Large
        static let xl: CGFloat = 18     // Extra large
        static let xl2: CGFloat = 22
        static let xl3: CGFloat = 26
        static let xl4: CGFloat = 34
        static let xl5: CGFloat = 42
        static let xl6: CGFloat = 52
        static let xl7: CGFloat = 82

        // Semantic aliases - point to the scale above
        static let caption = xs         // 7
        static let label = sm           // 9
        static let body = lg            // 15
        static let subheading = xl      // 18
        static let heading = xl3        // 26
        static let title = xl4          // 34
        static let display = xl5        // 42
        static let hero = xl7           // 82
    }
}

extension Font {
    static func custom(_ font: CustomFont, size: CGFloat) -> Font {
        return .custom(font.rawValue, size: size)
    }
}

// MARK: - Legacy Typography Support
struct CustomFonts {
    // Display fonts - Using Oswald Bold
    static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom("Oswald-Bold", size: size)
    }

    // Monospace font (JetBrains Mono)
    static func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName = weight == .bold ? "JetBrainsMono-Bold" : "JetBrainsMono-Regular"
        return .custom(fontName, size: size)
    }

    // UI font (SF Pro)
    static func ui(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Text Styles
extension Text {
    func displayStyle(size: CGFloat = 26, color: Color = .c2bText) -> some View {
        self
            .font(CustomFonts.display(size: size))
            .foregroundColor(color)
            .textCase(.uppercase)
            .tracking(0.26)
    }

    func monoStyle(size: CGFloat = 10, color: Color = .c2bMuted) -> some View {
        self
            .font(CustomFonts.mono(size: size, weight: .bold))
            .foregroundColor(color)
            .textCase(.uppercase)
            .tracking(1.6)
    }

    func uiStyle(size: CGFloat = 15, weight: Font.Weight = .regular, color: Color = .c2bText) -> some View {
        self
            .font(CustomFonts.ui(size: size, weight: weight))
            .foregroundColor(color)
    }
}

// MARK: - Common Gradients
struct C2BGradients {
    static let radialBackground = RadialGradient(
        colors: [
            Color(hex: "#161618"),
            Color(hex: "#050505")
        ],
        center: .top,
        startRadius: 0,
        endRadius: 600
    )

    static let tealGradient = LinearGradient(
        colors: [Color.c2bTeal, Color.c2bTealBright],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let bottomFade = LinearGradient(
        colors: [Color.clear, Color.c2bBackground],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Shadow Modifiers
extension View {
    func posterShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 10)
    }

    func cardShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 16)
    }

    func tabBarShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.55), radius: 10, x: 0, y: 10)
    }

    func tealGlow() -> some View {
        self
            .shadow(color: Color.c2bTeal.opacity(0.5), radius: 10, x: 0, y: 0)
    }
}

// MARK: - Common Shapes
struct C2BRoundedRectangle: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius)
    }
}

// MARK: - Blur Effect
extension View {
    func c2bBlur() -> some View {
        self
            .background(.ultraThinMaterial)
    }
}

// MARK: - Layout Constants
struct C2BLayout {
    static let horizontalPadding: CGFloat = 20
    static let posterAspectRatio: CGFloat = 2.0 / 3.0
    static let cardRadius: CGFloat = 16
    static let smallRadius: CGFloat = 12
    static let chipRadius: CGFloat = 999
}

// MARK: - RTL Support

/// Directional icon that automatically flips for RTL languages (Arabic, Hebrew, etc.)
struct DirectionalIcon: View {
    let systemName: String
    @Environment(\.layoutDirection) var layoutDirection

    /// Maps LTR icon names to their RTL equivalents
    private static let rtlMappings: [String: String] = [
        "chevron.left": "chevron.right",
        "chevron.right": "chevron.left",
        "arrow.left": "arrow.right",
        "arrow.right": "arrow.left",
        "arrow.left.circle": "arrow.right.circle",
        "arrow.right.circle": "arrow.left.circle",
        "arrow.left.circle.fill": "arrow.right.circle.fill",
        "arrow.right.circle.fill": "arrow.left.circle.fill",
        "chevron.backward": "chevron.forward",
        "chevron.forward": "chevron.forward",
        "arrow.backward": "arrow.forward",
        "arrow.forward": "arrow.backward"
    ]

    private var resolvedName: String {
        guard layoutDirection == .rightToLeft else { return systemName }
        return Self.rtlMappings[systemName] ?? systemName
    }

    var body: some View {
        Image(systemName: resolvedName)
    }
}

extension View {
    /// Flips the view horizontally when in RTL layout direction
    func flipForRTL() -> some View {
        modifier(RTLFlipModifier())
    }
}

private struct RTLFlipModifier: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: layoutDirection == .rightToLeft ? -1 : 1, y: 1)
    }
}
