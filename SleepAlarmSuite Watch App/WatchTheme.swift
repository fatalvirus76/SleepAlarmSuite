import SwiftUI
import Combine

// MARK: - Hex-färg (klockan)

extension Color {
    /// Färg från hex ("RRGGBB" / "RRGGBBAA" / "RGB").
    init(hexString hex: String) {
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

// MARK: - Klockteman

enum WatchTheme: String, CaseIterable, Identifiable {
    case midnatt
    case dracula
    case synthwave
    case gryning
    case glas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .midnatt: return "Midnatt"
        case .dracula: return "Dracula"
        case .synthwave: return "Synthwave"
        case .gryning: return "Gryning"
        case .glas: return "Glas"
        }
    }

    var icon: String {
        switch self {
        case .midnatt: return "moon.stars.fill"
        case .dracula: return "bolt.heart.fill"
        case .synthwave: return "sun.haze.fill"
        case .gryning: return "sunrise.fill"
        case .glas: return "snowflake"
        }
    }

    var palette: WatchPalette {
        switch self {
        case .midnatt:
            return WatchPalette(
                gradient: [Color(hexString: "050B18"), Color(hexString: "0D1730"), Color(hexString: "1B2A4A")],
                glow1: Color(hexString: "38BDF8").opacity(0.40),
                glow2: Color(hexString: "A78BFA").opacity(0.34),
                accent: Color(hexString: "7DD3FC"),
                accent2: Color(hexString: "A78BFA"),
                onAccent: Color(hexString: "07101F"),
                text: Color.white,
                textSecondary: Color(hexString: "A7B4C9"),
                cardFill: Color.white.opacity(0.10),
                fieldFill: Color.white.opacity(0.14),
                stroke: Color.white.opacity(0.14),
                isLight: false
            )

        case .dracula:
            return WatchPalette(
                gradient: [Color(hexString: "2B2D3A"), Color(hexString: "232430"), Color(hexString: "191A22")],
                glow1: Color(hexString: "BD93F9").opacity(0.40),
                glow2: Color(hexString: "FF79C6").opacity(0.32),
                accent: Color(hexString: "BD93F9"),
                accent2: Color(hexString: "FF79C6"),
                onAccent: Color(hexString: "1B1C25"),
                text: Color(hexString: "F8F8F2"),
                textSecondary: Color(hexString: "ADAFBD"),
                cardFill: Color.white.opacity(0.10),
                fieldFill: Color.white.opacity(0.14),
                stroke: Color.white.opacity(0.14),
                isLight: false
            )

        case .synthwave:
            return WatchPalette(
                gradient: [Color(hexString: "170A2A"), Color(hexString: "2B1055"), Color(hexString: "48146E")],
                glow1: Color(hexString: "FF2E97").opacity(0.42),
                glow2: Color(hexString: "00E5FF").opacity(0.34),
                accent: Color(hexString: "FF5FB2"),
                accent2: Color(hexString: "22D3EE"),
                onAccent: Color(hexString: "1A0620"),
                text: Color(hexString: "FFF0FA"),
                textSecondary: Color(hexString: "C6AFE0"),
                cardFill: Color.white.opacity(0.10),
                fieldFill: Color.white.opacity(0.14),
                stroke: Color(hexString: "FF2E97").opacity(0.30),
                isLight: false
            )

        case .gryning:
            return WatchPalette(
                gradient: [Color(hexString: "1B1023"), Color(hexString: "3A1C36"), Color(hexString: "6E3543")],
                glow1: Color(hexString: "FFB86B").opacity(0.40),
                glow2: Color(hexString: "FF7B9C").opacity(0.34),
                accent: Color(hexString: "FFB86B"),
                accent2: Color(hexString: "FF8FA3"),
                onAccent: Color(hexString: "2A1420"),
                text: Color(hexString: "FFF3E6"),
                textSecondary: Color(hexString: "DCC0C0"),
                cardFill: Color.white.opacity(0.12),
                fieldFill: Color.white.opacity(0.16),
                stroke: Color.white.opacity(0.16),
                isLight: false
            )

        case .glas:
            return WatchPalette(
                gradient: [Color(hexString: "DDE9FF"), Color(hexString: "EAF4FF"), Color(hexString: "CFF0EC")],
                glow1: Color(hexString: "60A5FA").opacity(0.34),
                glow2: Color(hexString: "2DD4BF").opacity(0.30),
                accent: Color(hexString: "0C5F79"),
                accent2: Color(hexString: "5B49C0"),
                onAccent: Color.white,
                text: Color(hexString: "0B1220"),
                textSecondary: Color(hexString: "36465E"),
                cardFill: Color.white.opacity(0.72),
                fieldFill: Color.white.opacity(0.88),
                stroke: Color(hexString: "0B1220").opacity(0.14),
                isLight: true
            )
        }
    }
}

struct WatchPalette {
    let gradient: [Color]
    let glow1: Color
    let glow2: Color
    let accent: Color
    let accent2: Color
    let onAccent: Color
    let text: Color
    let textSecondary: Color
    let cardFill: Color
    let fieldFill: Color
    let stroke: Color
    let isLight: Bool

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottomTrailing)
    }

    var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Statusfärger som funkar i både mörka och ljusa klockteman.
    var successSafe: Color { isLight ? Color(hexString: "0F7A5A") : Color(hexString: "4ADE80") }
    var warnSafe: Color { isLight ? Color(hexString: "9A6207") : Color(hexString: "FBBF24") }
    var dangerSafe: Color { isLight ? Color(hexString: "C02A2A") : Color(hexString: "FB7185") }
}

// MARK: - Manager

final class WatchThemeManager: ObservableObject {
    static let shared = WatchThemeManager()

    private static let key = "watchTheme"

    @Published var theme: WatchTheme {
        didSet { AppConfig.defaults.set(theme.rawValue, forKey: Self.key) }
    }

    var palette: WatchPalette { theme.palette }

    private init() {
        let stored = AppConfig.defaults.string(forKey: Self.key) ?? ""
        theme = WatchTheme(rawValue: stored) ?? .midnatt
    }

    func cycle() {
        let all = WatchTheme.allCases
        guard let idx = all.firstIndex(of: theme) else {
            theme = .midnatt
            return
        }
        theme = all[(idx + 1) % all.count]
    }
}

// MARK: - Bakgrund

/// Gradient + ljusglober. Globerna ligger i overlay med GeometryReader
/// (fasta storlekar i rot-ZStacken gör annars vyn bredare än klockans skärm).
struct WatchBackground: View {
    let palette: WatchPalette

    var body: some View {
        palette.backgroundGradient
            .overlay {
                GeometryReader { geo in
                    ZStack {
                        Circle()
                            .fill(palette.glow1)
                            .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                            .blur(radius: 40)
                            .offset(x: -geo.size.width * 0.30, y: -geo.size.height * 0.22)

                        Circle()
                            .fill(palette.glow2)
                            .frame(width: geo.size.width * 0.95, height: geo.size.width * 0.95)
                            .blur(radius: 45)
                            .offset(x: geo.size.width * 0.32, y: geo.size.height * 0.26)
                    }
                }
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()
    }
}

// MARK: - Byggstenar (klockan)

struct WatchCard<Content: View>: View {
    let palette: WatchPalette
    var padding: CGFloat = 10
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(palette.cardFill))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(palette.stroke, lineWidth: 1))
    }
}

struct WatchSectionTitle: View {
    let title: String
    let systemImage: String
    let palette: WatchPalette

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(palette.accent)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(0.8)
                .foregroundStyle(palette.textSecondary)
            Spacer(minLength: 0)
        }
    }
}

struct WatchPill: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 11, weight: .bold))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.22)))
        .foregroundStyle(color)
        .lineLimit(1)
    }
}

/// Stor +/- rad — lättare att träffa med fingret än en watch-slider.
struct WatchStepperRow: View {
    let title: String
    let valueText: String
    let palette: WatchPalette
    var onMinus: () -> Void
    var onPlus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                Spacer(minLength: 4)
                Text(valueText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(spacing: 8) {
                button("minus", action: onMinus)
                button("plus", action: onPlus)
            }
        }
    }

    private func button(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .heavy))
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(palette.accent.opacity(0.22))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(palette.accent.opacity(0.55), lineWidth: 1)
                )
                .foregroundStyle(palette.accent)
        }
        .buttonStyle(.plain)
    }
}

/// Val-knapp (chip) — stor text, tydligt valt läge.
struct WatchChip: View {
    let title: String
    let selected: Bool
    let palette: WatchPalette
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule().fill(selected ? AnyShapeStyle(palette.accentGradient) : AnyShapeStyle(palette.fieldFill))
                )
                .overlay(Capsule().strokeBorder(selected ? Color.clear : palette.stroke, lineWidth: 1))
                .foregroundStyle(selected ? palette.onAccent : palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .buttonStyle(.plain)
    }
}

/// Fullbredds-valrad (ikon + titel + bock) — används där chip-raden blir för trång,
/// t.ex. startläge och teman. Stor träffyta och ingen avkortad text.
struct WatchChoiceRow: View {
    let title: String
    let systemImage: String
    let selected: Bool
    let palette: WatchPalette
    var dots: [Color]? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(selected ? palette.onAccent : palette.accent)
                    .frame(width: 20, alignment: .center)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selected ? palette.onAccent : palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let dots {
                    HStack(spacing: 3) {
                        ForEach(Array(dots.enumerated()), id: \.offset) { _, color in
                            Circle()
                                .fill(color)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
                        }
                    }
                }

                Spacer(minLength: 4)

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(palette.onAccent)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(selected ? AnyShapeStyle(palette.accentGradient) : AnyShapeStyle(palette.fieldFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .strokeBorder(selected ? Color.clear : palette.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Stor temabunden knapp (primär/sekundär).
struct WatchActionButton: View {
    let title: String
    let systemImage: String
    let palette: WatchPalette
    var prominent: Bool = true
    var tint: Color? = nil
    var action: () -> Void

    private var color: Color { tint ?? palette.accent }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemImage).font(.system(size: 15, weight: .bold))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(prominent ? AnyShapeStyle(palette.accentGradient) : AnyShapeStyle(palette.fieldFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(prominent ? Color.clear : color.opacity(0.6), lineWidth: 1)
            )
            .foregroundStyle(prominent ? palette.onAccent : color)
        }
        .buttonStyle(.plain)
    }
}