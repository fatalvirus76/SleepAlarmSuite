import SwiftUI
import Combine

// MARK: - Hex-färg

extension Color {
    /// Skapar en färg från hex-sträng ("RRGGBB", "RRGGBBAA" eller "RGB").
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)

        let r: Double
        let g: Double
        let b: Double
        let a: Double

        switch s.count {
        case 3:
            r = Double((v >> 8) & 0xF) / 15.0
            g = Double((v >> 4) & 0xF) / 15.0
            b = Double(v & 0xF) / 15.0
            a = 1
        case 6:
            r = Double((v >> 16) & 0xFF) / 255.0
            g = Double((v >> 8) & 0xFF) / 255.0
            b = Double(v & 0xFF) / 255.0
            a = 1
        case 8:
            r = Double((v >> 24) & 0xFF) / 255.0
            g = Double((v >> 16) & 0xFF) / 255.0
            b = Double((v >> 8) & 0xFF) / 255.0
            a = Double(v & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0; a = 1
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Tema

enum AppTheme: String, CaseIterable, Identifiable {
    case midnatt
    case dracula
    case synthwave
    case glas
    case nord
    case gryning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midnatt: return "Midnatt"
        case .dracula: return "Dracula"
        case .synthwave: return "Synthwave"
        case .glas: return "Glas"
        case .nord: return "Nord"
        case .gryning: return "Gryning"
        }
    }

    var tagline: String {
        switch self {
        case .midnatt: return "Mörk nattblå"
        case .dracula: return "Lila & rosa"
        case .synthwave: return "Neon 80-tal"
        case .glas: return "Ljust & fruset"
        case .nord: return "Sval skandinavisk"
        case .gryning: return "Varm soluppgång"
        }
    }

    var icon: String {
        switch self {
        case .midnatt: return "moon.stars.fill"
        case .dracula: return "bolt.heart.fill"
        case .synthwave: return "sun.haze.fill"
        case .glas: return "snowflake"
        case .nord: return "cloud.snow.fill"
        case .gryning: return "sunrise.fill"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .midnatt:
            return ThemePalette(
                scheme: .dark,
                gradient: [Color(hex: "04070F"), Color(hex: "0B1220"), Color(hex: "17233C")],
                glow1: Color(hex: "38BDF8").opacity(0.34),
                glow2: Color(hex: "A78BFA").opacity(0.30),
                accent: Color(hex: "7DD3FC"),
                accent2: Color(hex: "A78BFA"),
                onAccent: Color(hex: "08111F"),
                text: Color(hex: "F8FAFC"),
                textSecondary: Color(hex: "9AA7BD"),
                cardTint: Color(hex: "7DD3FC").opacity(0.10),
                stroke: Color.white.opacity(0.10),
                ringTrack: Color.white.opacity(0.10),
                chipFill: Color.white.opacity(0.08),
                fieldFill: Color.white.opacity(0.06),
                success: Color(hex: "34D399"),
                warning: Color(hex: "FBBF24"),
                danger: Color(hex: "FB7185"),
                isLight: false
            )

        case .dracula:
            return ThemePalette(
                scheme: .dark,
                gradient: [Color(hex: "2B2D3A"), Color(hex: "22242F"), Color(hex: "191A22")],
                glow1: Color(hex: "BD93F9").opacity(0.34),
                glow2: Color(hex: "FF79C6").opacity(0.28),
                accent: Color(hex: "BD93F9"),
                accent2: Color(hex: "FF79C6"),
                onAccent: Color(hex: "1B1C25"),
                text: Color(hex: "F8F8F2"),
                textSecondary: Color(hex: "A8AAB8"),
                cardTint: Color(hex: "BD93F9").opacity(0.10),
                stroke: Color.white.opacity(0.10),
                ringTrack: Color.white.opacity(0.10),
                chipFill: Color.white.opacity(0.08),
                fieldFill: Color.white.opacity(0.06),
                success: Color(hex: "50FA7B"),
                warning: Color(hex: "F1FA8C"),
                danger: Color(hex: "FF5555"),
                isLight: false
            )

        case .synthwave:
            return ThemePalette(
                scheme: .dark,
                gradient: [Color(hex: "170A2A"), Color(hex: "2B1055"), Color(hex: "45126B")],
                glow1: Color(hex: "FF2E97").opacity(0.36),
                glow2: Color(hex: "00E5FF").opacity(0.30),
                accent: Color(hex: "FF5FB2"),
                accent2: Color(hex: "22D3EE"),
                onAccent: Color(hex: "1A0620"),
                text: Color(hex: "FFF0FA"),
                textSecondary: Color(hex: "C0A8DC"),
                cardTint: Color(hex: "FF2E97").opacity(0.12),
                stroke: Color(hex: "FF2E97").opacity(0.22),
                ringTrack: Color.white.opacity(0.12),
                chipFill: Color.white.opacity(0.08),
                fieldFill: Color.white.opacity(0.07),
                success: Color(hex: "22D3EE"),
                warning: Color(hex: "FFD166"),
                danger: Color(hex: "FF4D6D"),
                isLight: false
            )

        case .glas:
            return ThemePalette(
                scheme: .light,
                gradient: [Color(hex: "EFF4FF"), Color(hex: "F8FBFF"), Color(hex: "E6F6F4")],
                glow1: Color(hex: "60A5FA").opacity(0.30),
                glow2: Color(hex: "2DD4BF").opacity(0.26),
                accent: Color(hex: "0E7490"),
                accent2: Color(hex: "6D5BD0"),
                onAccent: Color.white,
                text: Color(hex: "0B1220"),
                textSecondary: Color(hex: "4A5A72"),
                cardTint: Color.white.opacity(0.40),
                stroke: Color.white.opacity(0.75),
                ringTrack: Color(hex: "0B1220").opacity(0.10),
                chipFill: Color.white.opacity(0.65),
                fieldFill: Color.white.opacity(0.70),
                success: Color(hex: "0F9B72"),
                warning: Color(hex: "B45309"),
                danger: Color(hex: "DC2626"),
                isLight: true
            )

        case .nord:
            return ThemePalette(
                scheme: .light,
                gradient: [Color(hex: "ECEFF4"), Color(hex: "E4E9F2"), Color(hex: "D8DEE9")],
                glow1: Color(hex: "5E81AC").opacity(0.24),
                glow2: Color(hex: "88C0D0").opacity(0.26),
                accent: Color(hex: "3B5B85"),
                accent2: Color(hex: "5E81AC"),
                onAccent: Color.white,
                text: Color(hex: "2E3440"),
                textSecondary: Color(hex: "4C566A"),
                cardTint: Color.white.opacity(0.42),
                stroke: Color.white.opacity(0.80),
                ringTrack: Color(hex: "2E3440").opacity(0.12),
                chipFill: Color.white.opacity(0.60),
                fieldFill: Color.white.opacity(0.70),
                success: Color(hex: "26806B"),
                warning: Color(hex: "A16207"),
                danger: Color(hex: "BF3A3A"),
                isLight: true
            )

        case .gryning:
            return ThemePalette(
                scheme: .dark,
                gradient: [Color(hex: "1B1023"), Color(hex: "3A1C36"), Color(hex: "6E3543")],
                glow1: Color(hex: "FFB86B").opacity(0.34),
                glow2: Color(hex: "FF7B9C").opacity(0.30),
                accent: Color(hex: "FFB86B"),
                accent2: Color(hex: "FF8FA3"),
                onAccent: Color(hex: "2A1420"),
                text: Color(hex: "FFF3E6"),
                textSecondary: Color(hex: "D6B8B8"),
                cardTint: Color(hex: "FFB86B").opacity(0.10),
                stroke: Color.white.opacity(0.12),
                ringTrack: Color.white.opacity(0.12),
                chipFill: Color.white.opacity(0.10),
                fieldFill: Color.white.opacity(0.08),
                success: Color(hex: "7BD389"),
                warning: Color(hex: "FFD166"),
                danger: Color(hex: "FF6B81"),
                isLight: false
            )
        }
    }
}

// MARK: - Palett

struct ThemePalette {
    let scheme: ColorScheme
    let gradient: [Color]
    let glow1: Color
    let glow2: Color
    let accent: Color
    let accent2: Color
    let onAccent: Color
    let text: Color
    let textSecondary: Color
    let cardTint: Color
    let stroke: Color
    let ringTrack: Color
    let chipFill: Color
    let fieldFill: Color
    let success: Color
    let warning: Color
    let danger: Color
    let isLight: Bool

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottomTrailing)
    }

    var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Material för kort — regular i ljusa teman (annars försvinner korten), ultraThin i mörka.
    var cardMaterial: Material { isLight ? .regularMaterial : .ultraThinMaterial }
}

// MARK: - ThemeManager

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private static let key = "appTheme"

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.key) }
    }

    var palette: ThemePalette { theme.palette }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.key) ?? ""
        theme = AppTheme(rawValue: stored) ?? .midnatt
    }

    func cycle() {
        let all = AppTheme.allCases
        guard let idx = all.firstIndex(of: theme) else {
            theme = .midnatt
            return
        }
        theme = all[(idx + 1) % all.count]
    }
}

// MARK: - Bakgrund

/// Temagradient + mjuka ljusglober. Globerna ligger i en overlay med GeometryReader
/// så att de aldrig kan göra roten bredare än skärmen.
struct AuroraBackground: View {
    let palette: ThemePalette

    var body: some View {
        palette.backgroundGradient
            .overlay {
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(palette.glow1)
                            .frame(width: geo.size.width * 0.95, height: geo.size.width * 0.95)
                            .blur(radius: 90)
                            .offset(x: -geo.size.width * 0.28, y: -geo.size.height * 0.20)

                        Circle()
                            .fill(palette.glow2)
                            .frame(width: geo.size.width * 0.85, height: geo.size.width * 0.85)
                            .blur(radius: 100)
                            .offset(x: geo.size.width * 0.30, y: geo.size.height * 0.28)
                    }
                }
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
    }
}

// MARK: - Byggstenar

struct ThemedCard<Content: View>: View {
    let palette: ThemePalette
    var padding: CGFloat = 16
    var radius: CGFloat = 22
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(palette.cardMaterial)
            }
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(palette.cardTint)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(palette.stroke, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(palette.isLight ? 0.10 : 0.34), radius: 18, y: 10)
    }
}

struct CardHeader: View {
    let title: String
    let systemImage: String
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.accent)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.1)
                .foregroundStyle(palette.text)
            Spacer(minLength: 0)
        }
    }
}

struct StatusPill: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage).font(.system(size: 11, weight: .bold))
            Text(text).font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.18)))
        .foregroundStyle(color)
    }
}

struct ThemeChip: View {
    let title: String
    let selected: Bool
    let palette: ThemePalette
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(selected ? AnyShapeStyle(palette.accentGradient) : AnyShapeStyle(palette.chipFill))
                )
                .overlay(
                    Capsule().strokeBorder(selected ? Color.clear : palette.stroke, lineWidth: 1)
                )
                .foregroundStyle(selected ? palette.onAccent : palette.text)
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    let palette: ThemePalette
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage).font(.system(size: 17, weight: .bold))
                Text(title).font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(palette.accentGradient))
            .foregroundStyle(palette.onAccent)
            .shadow(color: palette.accent.opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    let systemImage: String
    let palette: ThemePalette
    var tint: Color? = nil
    var action: () -> Void

    private var color: Color { tint ?? palette.accent }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage).font(.system(size: 15, weight: .bold))
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(palette.chipFill))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(color.opacity(0.55), lineWidth: 1))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

struct ThemedField: View {
    let title: String
    @Binding var text: String
    let palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(1)
                .foregroundStyle(palette.textSecondary)

            TextField(title, text: $text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(palette.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(palette.fieldFill))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(palette.stroke, lineWidth: 1))
        }
    }
}

struct SliderRow: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                Spacer(minLength: 8)
                Text(valueText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.accent)
            }
            Slider(value: $value, in: range, step: step)
                .tint(palette.accent)
        }
    }
}

struct LabeledRow<Content: View>: View {
    let title: String
    let systemImage: String
    let palette: ThemePalette
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 22)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.text)
            Spacer(minLength: 8)
            content
        }
    }
}

/// Ring som visar hur långt in på sömnen du är.
struct WakeRing: View {
    let progress: Double
    let palette: ThemePalette
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.ringTrack, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.0001, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [palette.accent, palette.accent2, palette.accent]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}