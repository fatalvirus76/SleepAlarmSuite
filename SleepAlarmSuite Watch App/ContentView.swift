import SwiftUI
import WatchKit

// Flik 1: Larm — nästa väckning + snabbåtgärder.
struct ContentView: View {
    @EnvironmentObject private var store: AlarmStore
    @EnvironmentObject private var scheduler: AlarmScheduler
    @EnvironmentObject private var hk: HealthKitSleepManager
    @EnvironmentObject private var wc: WatchConnectivityManager
    @ObservedObject private var theme = WatchThemeManager.shared

    @AppStorage("useCustom", store: AppConfig.defaults) private var useCustom: Bool = false
    @AppStorage("presetRaw", store: AppConfig.defaults) private var presetRaw: String = Preset.h8.rawValue
    @AppStorage("customHours", store: AppConfig.defaults) private var customHours: Double = 8.0
    @AppStorage("smartWindowMinutes", store: AppConfig.defaults) private var smartWindowMinutes: Double = 20
    @AppStorage("windowStepMinutes", store: AppConfig.defaults) private var windowStepMinutes: Double = 5
    @AppStorage("snoozeMinutes", store: AppConfig.defaults) private var snoozeMinutes: Int = 9
    @AppStorage("label", store: AppConfig.defaults) private var label: String = "Sömn-larm"

    private var p: WatchPalette { theme.palette }
    private var preset: Preset { Preset(rawValue: presetRaw) ?? .h8 }
    private var durationSeconds: TimeInterval { useCustom ? customHours * 3600 : preset.seconds }
    private var activePlan: AlarmPlan? {
        guard let plan = store.currentPlan, plan.enabled else { return nil }
        return plan
    }
    private var notificationsOn: Bool {
        scheduler.authorizationStatus == .authorized || scheduler.authorizationStatus == .provisional
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                heroCard
                quickPills
                actions
                planSummary

                if let msg = wc.lastMessage {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundStyle(p.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let err = scheduler.lastError {
                    messageLine(err, color: p.dangerSafe)
                }
                if let err = hk.lastError {
                    messageLine(err, color: p.warnSafe)
                }
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 14)
        }
        .background(WatchBackground(palette: p))
    }

    // MARK: Hero

    private var heroCard: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            WatchCard(palette: p, padding: 12) {
                VStack(spacing: 10) {
                    WatchSectionTitle(
                        title: activePlan == nil ? "Inget larm" : "Nästa väckning",
                        systemImage: activePlan == nil ? "moon.zzz.fill" : "moon.stars.fill",
                        palette: p
                    )

                    ZStack {
                        ring(progress: ringProgress(at: context.date))
                            .frame(width: 122, height: 122)

                        VStack(spacing: 1) {
                            Text(activePlan == nil ? "--:--" : activePlan!.lastFireDate.formattedTimeSV())
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(p.accentGradient)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)

                            Text(heroSubline(at: context.date))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(p.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, 16)
                    }

                    if let plan = activePlan, plan.smartWindowSeconds > 0 {
                        Text("\(plan.firstFireDate.formattedTimeSV()) – \(plan.lastFireDate.formattedTimeSV())")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(p.text)
                    }
                }
            }
        }
    }

    private func ring(progress: Double) -> some View {
        ZStack {
            Circle().stroke(Color.white.opacity(p.isLight ? 0.35 : 0.14), lineWidth: 9)
            Circle()
                .trim(from: 0, to: max(0.0001, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [p.accent, p.accent2, p.accent]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }

    private func ringProgress(at date: Date) -> Double {
        guard let plan = activePlan, plan.targetDurationSeconds > 0 else { return 0 }
        let elapsed = date.timeIntervalSince(plan.sleepStart)
        return min(max(elapsed / plan.targetDurationSeconds, 0), 1)
    }

    private func heroSubline(at date: Date) -> String {
        guard let plan = activePlan else { return "Tryck Starta" }
        let left = plan.lastFireDate.timeIntervalSince(date)
        if left <= 0 { return "passerad" }
        return "\(TimeInterval(left).asHoursMinutesSV()) kvar"
    }

    // MARK: Pills

    private var quickPills: some View {
        HStack(spacing: 6) {
            WatchPill(
                text: notificationsOn ? "Notiser" : "Inga notiser",
                systemImage: notificationsOn ? "bell.fill" : "bell.slash.fill",
                color: notificationsOn ? p.successSafe : p.dangerSafe
            )
            WatchPill(
                text: wc.isReachable ? "iPhone nåbar" : (wc.isActivated ? "Synkad" : "Ej synkad"),
                systemImage: "applewatch",
                color: wc.isReachable ? p.successSafe : p.textSecondary
            )
            Spacer(minLength: 0)
        }
    }

    // MARK: Åtgärder

    private var actions: some View {
        VStack(spacing: 9) {
            if scheduler.authorizationStatus == .notDetermined {
                WatchActionButton(title: "Tillåt notiser", systemImage: "bell.badge.fill", palette: p, prominent: false) {
                    Task { await scheduler.requestAuthorization() }
                }
            }

            WatchActionButton(title: "Starta sömn-larm", systemImage: "bed.double.fill", palette: p) {
                Task { await startSleep() }
            }

            if let plan = activePlan {
                WatchActionButton(title: "Snooze +\(plan.snoozeMinutes)", systemImage: "clock.arrow.circlepath", palette: p, prominent: false) {
                    Task {
                        let snoozed = await scheduler.snooze(plan: plan)
                        store.currentPlan = snoozed
                        await scheduler.schedule(plan: snoozed)
                        wc.sendPlan(snoozed)
                        WKInterfaceDevice.current().play(.directionDown)
                    }
                }

                HStack(spacing: 8) {
                    WatchActionButton(title: "Stoppa", systemImage: "stop.fill", palette: p, prominent: false, tint: p.dangerSafe) {
                        Task {
                            await scheduler.clearPendingForPrefix()
                            store.currentPlan = nil
                            wc.sendAction("stop")
                            WKInterfaceDevice.current().play(.click)
                        }
                    }

                    WatchActionButton(title: "Testa", systemImage: "waveform.path", palette: p, prominent: false) {
                        WKInterfaceDevice.current().play(.notification)
                    }
                }
            } else {
                WatchActionButton(title: "Testa haptik", systemImage: "waveform.path", palette: p, prominent: false) {
                    WKInterfaceDevice.current().play(.notification)
                }
            }
        }
    }

    // MARK: Plankort

    private var planSummary: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 9) {
                WatchSectionTitle(title: "Plan", systemImage: "slider.horizontal.3", palette: p)

                row("Etikett", label.isEmpty ? "Sömn-larm" : label)
                row("Sömnlängd", durationSeconds.asHoursMinutesSV())
                row("Smart fönster", smartWindowMinutes > 0 ? "\(Int(smartWindowMinutes)) min" : "Av")
                row("Snooze", "\(snoozeMinutes) min")

                Text("Ändra under Planera-fliken.")
                    .font(.system(size: 11))
                    .foregroundStyle(p.textSecondary)
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(p.textSecondary)
            Spacer(minLength: 6)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(p.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func messageLine(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.18)))
    }

    // MARK: Logik

    private func startSleep() async {
        var start = Date()
        let mode = AppConfig.defaults.string(forKey: SettingsKeys.startMode) ?? StartModeOption.now.rawValue
        switch StartModeOption(rawValue: mode) ?? .now {
        case .now:
            start = Date()
        case .manual:
            let cal = Calendar.current
            let now = Date()
            let hour = AppConfig.defaults.object(forKey: SettingsKeys.manualHour) as? Int ?? cal.component(.hour, from: now)
            let minute = AppConfig.defaults.object(forKey: SettingsKeys.manualMinute) as? Int ?? cal.component(.minute, from: now)
            start = cal.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        case .autoHK:
            if !hk.authorized { await hk.requestAuthorization() }
            let detected = await hk.detectRecentSleepStart()
            start = detected ?? Date()
        }

        let plan = AlarmPlan.make(
            sleepStart: start,
            durationSeconds: durationSeconds,
            smartWindowSeconds: smartWindowMinutes * 60,
            windowStepSeconds: windowStepMinutes * 60,
            snoozeMinutes: snoozeMinutes,
            label: label.isEmpty ? "Sömn-larm" : label
        )

        store.currentPlan = plan
        store.addSession(SleepSession(
            id: UUID(),
            startedAt: start,
            plannedDurationSeconds: durationSeconds,
            smartWindowSeconds: smartWindowMinutes * 60,
            snoozeMinutes: snoozeMinutes,
            label: plan.label
        ))

        WKInterfaceDevice.current().play(.success)
        await scheduler.schedule(plan: plan)

        // Synka planen till iPhone (den schemalägger sina egna notiser).
        wc.sendPlan(plan)
    }
}