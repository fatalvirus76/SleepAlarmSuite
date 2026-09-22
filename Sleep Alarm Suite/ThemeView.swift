import SwiftUI

struct ThemeView: View {
    @ObservedObject private var theme = ThemeManager.shared

    private var p: ThemePalette { theme.palette }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    previewCard

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AppTheme.allCases) { item in
                            themeCard(item)
                        }
                    }

                    Text("Temat gäller hela appen och sparas direkt.")
                        .font(.system(size: 12))
                        .foregroundStyle(p.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(AuroraBackground(palette: p))
            .navigationTitle("Tema")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Förhandsvisning

    private var previewCard: some View {
        ThemedCard(palette: p, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                CardHeader(title: theme.theme.title, systemImage: theme.theme.icon, palette: p)

                HStack(spacing: 14) {
                    WakeRing(progress: 0.62, palette: p, lineWidth: 9)
                        .frame(width: 78, height: 78)
                        .overlay {
                            Text("07:30")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(p.accentGradient)
                        }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Så här ser larmkortet ut")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(p.text)
                        Text(theme.theme.tagline)
                            .font(.system(size: 12))
                            .foregroundStyle(p.textSecondary)
                        HStack(spacing: 6) {
                            StatusPill(text: "Notiser på", systemImage: "bell.fill", color: p.success)
                            StatusPill(text: "8h mål", systemImage: "hourglass", color: p.accent)
                        }
                        .padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    Text("Accent")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(p.textSecondary)
                    Capsule().fill(p.accent).frame(width: 34, height: 12)
                    Capsule().fill(p.accent2).frame(width: 34, height: 12)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: Temakort

    private func themeCard(_ item: AppTheme) -> some View {
        let tp = item.palette
        let selected = theme.theme == item

        return Button {
            withAnimation(.easeInOut(duration: 0.35)) { theme.theme = item }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tp.backgroundGradient)
                        .frame(height: 74)

                    HStack(spacing: 8) {
                        Circle().fill(tp.accent).frame(width: 18, height: 18)
                        Circle().fill(tp.accent2).frame(width: 18, height: 18)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(selected ? tp.accent : Color.white.opacity(0.15), lineWidth: selected ? 2 : 1)
                }

                HStack(spacing: 6) {
                    Image(systemName: item.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(p.accent)
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(p.text)
                    Spacer(minLength: 0)
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(p.accent)
                    }
                }

                Text(item.tagline)
                    .font(.system(size: 11))
                    .foregroundStyle(p.textSecondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.cardMaterial)
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(p.cardTint)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(selected ? p.accent.opacity(0.8) : p.stroke, lineWidth: selected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}