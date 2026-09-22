import SwiftUI
import WatchKit

// Flik 2: Planera — alla inställningar med stora, lätttryckta kontroller.
struct PlanView: View {
    @EnvironmentObject private var hk: HealthKitSleepManager
    @ObservedObject private var theme = WatchThemeManager.shared

    @AppStorage("useCustom", store: AppConfig.defaults) private var useCustom: Bool = false
    @AppStorage("presetRaw", store: AppConfig.defaults) private var presetRaw: String = Preset.h8.rawValue
    @AppStorage("customHours", store: AppConfig.defaults) private var customHours: Double = 8.0
    @AppStorage("smartWindowMinutes", store: AppConfig.defaults) private var smartWindowMinutes: Double = 20
    @AppStorage("windowStepMinutes", store: AppConfig.defaults) private var windowStepMinutes: Double = 5
    @AppStorage("snoozeMinutes", store: AppConfig.defaults) private var snoozeMinutes: Int = 9
    @AppStorage("label", store: AppConfig.defaults) private var label: String = "Sömn-larm"

    @AppStorage(SettingsKeys.startMode, store: AppConfig.defaults) private var startModeRaw: String = StartModeOption.now.rawValue
    @AppStorage(SettingsKeys.manualHour, store: AppConfig.defaults) private var manualHour: Int = 22
    @AppStorage(SettingsKeys.manualMinute, store: AppConfig.defaults) private var manualMinute: Int = 30

    @State private var isAutoDetecting: Bool = false

    private var p: WatchPalette { theme.palette }
    private var preset: Preset { Preset(rawValue: presetRaw) ?? .h8 }
    private var startMode: StartModeOption { StartModeOption(rawValue: startModeRaw) ?? .now }
    private var durationSeconds: TimeInterval { useCustom ? customHours * 3600 : preset.seconds }

    private let threeColumns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                labelCard
                startCard
                durationCard
                windowCard
                snoozeCard

                Text("\(durationSeconds.asHoursMinutesSV()) sömn från \(startPreview())")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(p.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 14)
        }
        .background(WatchBackground(palette: p))
    }

    // MARK: Etikett

    private var labelCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                WatchSectionTitle(title: "Etikett", systemImage: "tag.fill", palette: p)
                TextField("Sömn-larm", text: $label)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(p.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(p.fieldFill))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(p.stroke, lineWidth: 1))
            }
        }
    }

    // MARK: Start

    private var startCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                WatchSectionTitle(title: "Start", systemImage: "play.circle.fill", palette: p)

                HStack(spacing: 6) {
                    ForEach(StartModeOption.allCases) { mode in
                        WatchChip(title: mode.short, selected: startMode == mode, palette: p) {
                            withAnimation(.easeInOut(duration: 0.2)) { startModeRaw = mode.rawValue }
                        }
                    }
                }

                switch startMode {
                case .now:
                    Text("Startar direkt när du trycker Starta.")
                        .font(.system(size: 13))
                        .foregroundStyle(p.textSecondary)

                case .manual:
                    VStack(spacing: 12) {
                        WatchStepperRow(
                            title: "Timme",
                            valueText: String(format: "%02d", manualHour),
                            palette: p,
                            onMinus: { manualHour = (manualHour + 23) % 24 },
                            onPlus: { manualHour = (manualHour + 1) % 24 }
                        )

                        WatchStepperRow(
                            title: "Minut",
                            valueText: String(format: "%02d", manualMinute),
                            palette: p,
                            onMinus: { manualMinute = (manualMinute + 55) % 60 },
                            onPlus: { manualMinute = (manualMinute + 5) % 60 }
                        )

                        Text("Start kl. \(String(format: "%02d:%02d", manualHour, manualMinute))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(p.accent)
                    }

                case .autoHK:
                    VStack(alignment: .leading, spacing: 10) {
                        Text(hk.lastDetectedSleepStart == nil
                             ? "Ingen insomning hittad än."
                             : "Senaste insomning: \(hk.lastDetectedSleepStart!.formattedDateTimeSV())")
                            .font(.system(size: 13))
                            .foregroundStyle(p.textSecondary)

                        WatchActionButton(
                            title: isAutoDetecting ? "Söker…" : "Hämta från HealthKit",
                            systemImage: "wand.and.stars",
                            palette: p,
                            prominent: false
                        ) {
                            Task { await autoDetect() }
                        }
                    }
                }
            }
        }
    }

    private func startPreview() -> String {
        switch startMode {
        case .now:
            return "nu"
        case .manual:
            return "kl. \(String(format: "%02d:%02d", manualHour, manualMinute))"
        case .autoHK:
            return hk.lastDetectedSleepStart.map { "kl. \($0.formattedTimeSV())" } ?? "nu"
        }
    }

    // MARK: Sömnlängd

    private var durationCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                WatchSectionTitle(title: "Sömnlängd", systemImage: "hourglass", palette: p)

                LazyVGrid(columns: threeColumns, spacing: 6) {
                    ForEach(Preset.allCases) { item in
                        WatchChip(title: item.rawValue, selected: !useCustom && preset == item, palette: p) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                useCustom = false
                                presetRaw = item.rawValue
                            }
                        }
                    }
                    WatchChip(title: "Egen", selected: useCustom, palette: p) {
                        withAnimation(.easeInOut(duration: 0.2)) { useCustom = true }
                    }
                }

                if useCustom {
                    WatchStepperRow(
                        title: "Timmar",
                        valueText: String(format: "%.1f", customHours),
                        palette: p,
                        onMinus: { customHours = max(4, customHours - 0.5) },
                        onPlus: { customHours = min(12, customHours + 0.5) }
                    )
                }
            }
        }
    }

    // MARK: Smart fönster

    private var windowCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 12) {
                WatchSectionTitle(title: "Smart fönster", systemImage: "wind", palette: p)

                WatchStepperRow(
                    title: "Fönster",
                    valueText: smartWindowMinutes > 0 ? "\(Int(smartWindowMinutes)) min" : "Av",
                    palette: p,
                    onMinus: { smartWindowMinutes = max(0, smartWindowMinutes - 5) },
                    onPlus: { smartWindowMinutes = min(60, smartWindowMinutes + 5) }
                )

                if smartWindowMinutes > 0 {
                    WatchStepperRow(
                        title: "Steg mellan larm",
                        valueText: "\(Int(windowStepMinutes)) min",
                        palette: p,
                        onMinus: { windowStepMinutes = max(1, windowStepMinutes - 1) },
                        onPlus: { windowStepMinutes = min(15, windowStepMinutes + 1) }
                    )

                    Text("Väcker någonstans i fönstret före måltiden.")
                        .font(.system(size: 12))
                        .foregroundStyle(p.textSecondary)
                }
            }
        }
    }

    // MARK: Snooze

    private var snoozeCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                WatchSectionTitle(title: "Snooze (min)", systemImage: "clock.arrow.circlepath", palette: p)

                LazyVGrid(columns: threeColumns, spacing: 6) {
                    ForEach([3, 5, 7, 9, 10, 15], id: \.self) { value in
                        WatchChip(title: "\(value)", selected: snoozeMinutes == value, palette: p) {
                            withAnimation(.easeInOut(duration: 0.2)) { snoozeMinutes = value }
                        }
                    }
                }
            }
        }
    }

    // MARK: Logik

    private func autoDetect() async {
        isAutoDetecting = true
        defer { isAutoDetecting = false }
        if !hk.authorized {
            await hk.requestAuthorization()
        }
        _ = await hk.detectRecentSleepStart()
        WKInterfaceDevice.current().play(.click)
    }
}