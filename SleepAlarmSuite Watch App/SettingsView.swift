import SwiftUI
import WatchKit

// Flik 4: Inställningar — tema, notiser, HealthKit och klock-status.
struct SettingsView: View {
    @EnvironmentObject private var scheduler: AlarmScheduler
    @EnvironmentObject private var hk: HealthKitSleepManager
    @EnvironmentObject private var wc: WatchConnectivityManager
    @ObservedObject private var theme = WatchThemeManager.shared

    private var p: WatchPalette { theme.palette }
    private var notificationsOn: Bool {
        scheduler.authorizationStatus == .authorized || scheduler.authorizationStatus == .provisional
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                themeCard
                notificationsCard
                healthCard
                watchCard
                aboutCard
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 14)
        }
        .background(WatchBackground(palette: p))
    }

    // MARK: Tema

    private var themeCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                WatchSectionTitle(title: "Tema", systemImage: "paintpalette.fill", palette: p)

                HStack(spacing: 10) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(p.isLight ? 0.35 : 0.15), lineWidth: 7)
                        Circle()
                            .trim(from: 0, to: 0.68)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [p.accent, p.accent2, p.accent]),
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 7, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 54, height: 54)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(theme.theme.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(p.text)
                        Text("Aktuellt tema")
                            .font(.system(size: 12))
                            .foregroundStyle(p.textSecondary)
                    }
                    Spacer(minLength: 0)
                }

                VStack(spacing: 6) {
                    ForEach(WatchTheme.allCases) { item in
                        WatchChoiceRow(
                            title: item.title,
                            systemImage: item.icon,
                            selected: theme.theme == item,
                            palette: p,
                            dots: [item.palette.accent, item.palette.accent2]
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) { theme.theme = item }
                            WKInterfaceDevice.current().play(.click)
                        }
                    }
                }
            }
        }
    }

    // MARK: Notiser

    private var notificationsCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    WatchSectionTitle(title: "Notiser", systemImage: "bell.fill", palette: p)
                    WatchPill(
                        text: notificationsOn ? "På" : "Av",
                        systemImage: notificationsOn ? "checkmark" : "xmark",
                        color: notificationsOn ? p.successSafe : p.dangerSafe
                    )
                }

                Text("Behövs för att väcka med haptik och notis.")
                    .font(.system(size: 12))
                    .foregroundStyle(p.textSecondary)

                WatchActionButton(title: "Begär tillstånd", systemImage: "bell.badge.fill", palette: p, prominent: !notificationsOn) {
                    Task { await scheduler.requestAuthorization() }
                }
            }
        }
    }

    // MARK: HealthKit

    private var healthCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    WatchSectionTitle(title: "HealthKit", systemImage: "heart.fill", palette: p)
                    WatchPill(
                        text: hk.authorized ? "Kopplad" : "Ej kopplad",
                        systemImage: hk.authorized ? "checkmark" : "xmark",
                        color: hk.authorized ? p.successSafe : p.textSecondary
                    )
                }

                Text("Används för att hitta senaste insomningstid (Auto-läget).")
                    .font(.system(size: 12))
                    .foregroundStyle(p.textSecondary)

                if let d = hk.lastDetectedSleepStart {
                    Text("Senast upptäckt: \(d.formattedDateTimeSV())")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(p.accent)
                }

                WatchActionButton(title: "Aktivera HealthKit", systemImage: "heart.text.square.fill", palette: p, prominent: !hk.authorized) {
                    Task { await hk.requestAuthorization() }
                }
            }
        }
    }

    // MARK: Klocka / synk

    private var watchCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                WatchSectionTitle(title: "Synk med iPhone", systemImage: "applewatch", palette: p)

                statusRow("Session aktiv", ok: wc.isActivated)
                statusRow("iPhone nåbar", ok: wc.isReachable)

                WatchActionButton(title: "Hämta plan från iPhone", systemImage: "arrow.down.circle.fill", palette: p, prominent: false) {
                    wc.requestPlanFromPhone()
                }

                if let msg = wc.lastMessage {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundStyle(p.textSecondary)
                }
            }
        }
    }

    private func statusRow(_ title: String, ok: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(p.textSecondary)
            Spacer(minLength: 6)
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ok ? p.successSafe : p.textSecondary)
        }
    }

    // MARK: Om

    private var aboutCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                WatchSectionTitle(title: "Om", systemImage: "info.circle.fill", palette: p)

                HStack(alignment: .firstTextBaseline) {
                    Text("Sleep Alarm Suite")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(p.text)
                    Spacer(minLength: 6)
                    Text(version)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(p.accent)
                }

                Text("Väcker dig i ett smart fönster efter din planerade sömn.")
                    .font(.system(size: 12))
                    .foregroundStyle(p.textSecondary)
            }
        }
    }

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }
}