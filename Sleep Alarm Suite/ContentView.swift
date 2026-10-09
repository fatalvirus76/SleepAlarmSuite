import SwiftUI
import UserNotifications

// Rot-vy: flikar (Larm / Statistik / Tema). Temat styr färger, bakgrund och material.
struct ContentView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @AppStorage("lastTab") private var lastTab: Int = 0

    var body: some View {
        TabView(selection: $lastTab) {
            AlarmView()
                .tabItem { Label(L("Larm"), systemImage: "alarm.fill") }
                .tag(0)

            StatsView()
                .tabItem { Label(L("Statistik"), systemImage: "chart.bar.xaxis") }
                .tag(1)

            ThemeView()
                .tabItem { Label(L("Tema"), systemImage: "paintpalette.fill") }
                .tag(2)
        }
        .tint(theme.palette.accent)
        .preferredColorScheme(theme.palette.scheme)
    }
}

// MARK: - Larm

struct AlarmView: View {
    @EnvironmentObject private var store: AlarmStore
    @EnvironmentObject private var scheduler: AlarmScheduler
    @EnvironmentObject private var hk: HealthKitSleepManager
    @EnvironmentObject private var wc: PhoneConnectivityManager
    @EnvironmentObject private var phoneAlarms: PhoneAlarmManager
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var i18n = I18nManager.shared

    @AppStorage("useCustom") private var useCustom: Bool = false
    @AppStorage("presetRaw") private var presetRaw: String = Preset.h8.rawValue
    @AppStorage("customHours") private var customHours: Double = 8.0

    @AppStorage("smartWindowMinutes") private var smartWindowMinutes: Double = 20
    @AppStorage("windowStepMinutes") private var windowStepMinutes: Double = 5
    @AppStorage("snoozeMinutes") private var snoozeMinutes: Int = 9
    @AppStorage("label") private var label: String = L("Sömn-larm")

    // Sparas mellan appstarter (samma beteende som klockappen).
    @AppStorage("startModeRaw") private var startModeRaw: String = StartMode.now.rawValue
    private var startMode: StartMode {
        get { StartMode(rawValue: startModeRaw) ?? .now }
        nonmutating set { startModeRaw = newValue.rawValue }
    }
    @State private var manualStart: Date = Date()
    @State private var isAutoDetecting: Bool = false

    enum StartMode: String, CaseIterable, Identifiable {
        case now = "now"
        case manual = "manual"
        case autoHK = "autoHK"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .now: return L("Nu")
            case .manual: return L("Manuellt")
            case .autoHK: return L("Auto (Health)")
            }
        }

        var icon: String {
            switch self {
            case .now: return "bolt.fill"
            case .manual: return "clock.fill"
            case .autoHK: return "wand.and.stars"
            }
        }
    }

    private var p: ThemePalette { theme.palette }
    private var preset: Preset { Preset(rawValue: presetRaw) ?? .h8 }
    private var durationSeconds: TimeInterval { useCustom ? customHours * 3600 : preset.seconds }
    private var notificationsOn: Bool {
        scheduler.authorizationStatus == .authorized || scheduler.authorizationStatus == .provisional
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    actionButtons
                    plannerCard
                    watchCard

                    if let err = scheduler.lastError {
                        errorLine(err, color: p.danger, icon: "exclamationmark.triangle.fill")
                    }
                    if let err = hk.lastError {
                        errorLine(err, color: p.warning, icon: "heart.slash.fill")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(AuroraBackground(palette: p))
            .navigationTitle("Sleep Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.35)) { theme.cycle() }
                    } label: {
                        Image(systemName: theme.theme.icon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .tint(p.accent)
                }
            }
        }
    }

    // MARK: Hero

    private var heroCard: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            ThemedCard(palette: p, padding: 20) {
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: activePlan == nil ? "moon.zzz.fill" : "moon.stars.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(p.accent)
                        Text(activePlan == nil ? L("INGET AKTIVT LARM") : L("NÄSTA VÄCKNING"))
                            .font(.system(size: 12, weight: .heavy))
                            .tracking(1.2)
                            .foregroundStyle(p.textSecondary)
                        Spacer(minLength: 0)
                        StatusPill(
                            text: notificationsOn ? L("Notiser på") : L("Notiser av"),
                            systemImage: notificationsOn ? "bell.fill" : "bell.slash.fill",
                            color: notificationsOn ? p.success : p.danger
                        )
                    }

                    ZStack {
                        WakeRing(progress: ringProgress(at: context.date), palette: p)
                            .frame(width: 196, height: 196)

                        VStack(spacing: 4) {
                            Text(activePlan == nil ? "--:--" : activePlan!.lastFireDate.formattedTimeSV())
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(p.accentGradient)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)

                            Text(heroSubline(at: context.date))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(p.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 26)
                    }

                    if let plan = activePlan, plan.smartWindowSeconds > 0 {
                        windowBar(plan: plan, now: context.date)
                    }

                    HStack(spacing: 8) {
                        StatusPill(
                            text: targetLabel(activePlan) + " " + L("mål"),
                            systemImage: "hourglass",
                            color: p.accent
                        )
                        StatusPill(
                            text: wc.isPaired ? (wc.isReachable ? L("Klocka nära") : L("Klocka parad")) : L("Ingen klocka"),
                            systemImage: "applewatch",
                            color: wc.isPaired ? p.success : p.textSecondary
                        )
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private func targetLabel(_ plan: AlarmPlan?) -> String {
        guard let plan else { return durationSeconds.asHoursMinutesSV() }
        return plan.targetDurationSeconds.asHoursMinutesSV()
    }

    private var activePlan: AlarmPlan? {
        guard let plan = store.currentPlan, plan.enabled else { return nil }
        // En plan vars väckningsfönster passerat räknas inte som aktiv längre,
        // även om städningen (cleanupPassedPlan) inte hunnit köras än.
        guard plan.lastFireDate > Date() else { return nil }
        return plan
    }

    private func ringProgress(at date: Date) -> Double {
        guard let plan = activePlan, plan.targetDurationSeconds > 0 else { return 0 }
        let elapsed = date.timeIntervalSince(plan.sleepStart)
        return min(max(elapsed / plan.targetDurationSeconds, 0), 1)
    }

    private func heroSubline(at date: Date) -> String {
        guard let plan = activePlan else { return L("Ingen plan ännu — tryck Starta nedan") }
        let left = plan.lastFireDate.timeIntervalSince(date)
        if left <= 0 { return L("Väckning passerad") }
        return L("%@ kvar", TimeInterval(left).asHoursMinutesSV())
    }

    private func windowBar(plan: AlarmPlan, now: Date) -> some View {
        let total = max(plan.smartWindowSeconds, 60)
        let frac = min(max(now.timeIntervalSince(plan.firstFireDate) / total, 0), 1)

        return VStack(spacing: 7) {
            HStack {
                Text(plan.firstFireDate.formattedTimeSV())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(p.text)
                Spacer(minLength: 6)
                Text(L("Smart fönster %d min • steg %d min", Int(plan.smartWindowSeconds / 60), Int(plan.windowStepSeconds / 60)))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(p.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 6)
                Text(plan.lastFireDate.formattedTimeSV())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(p.text)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(p.ringTrack)
                    Capsule()
                        .fill(p.accentGradient)
                        .frame(width: max(6, geo.size.width * frac))
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: Knappar

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if scheduler.authorizationStatus == .notDetermined {
                SecondaryButton(title: L("Aktivera notiser"), systemImage: "bell.badge.fill", palette: p) {
                    Task { await scheduler.requestAuthorization() }
                }
            }

            PrimaryButton(title: L("Starta sömn-larm"), systemImage: "bed.double.fill", palette: p) {
                Task { await startSleep() }
            }

            if let plan = activePlan {
                HStack(spacing: 10) {
                    SecondaryButton(title: L("Snooze") + " +\(plan.snoozeMinutes)", systemImage: "clock.arrow.circlepath", palette: p) {
                        Task {
                            var snoozed = await scheduler.snooze(plan: plan)
                            snoozed.notifier = "phone"
                            store.currentPlan = snoozed
                            await scheduler.schedule(plan: snoozed)
                            await phoneAlarms.schedule(for: snoozed)
                            wc.sendPlan(snoozed)
                        }
                    }

                    SecondaryButton(title: L("Stoppa"), systemImage: "stop.fill", palette: p, tint: p.danger) {
                        Task {
                            phoneAlarms.cancel(for: plan.id)
                            await scheduler.clearPendingForPrefix()
                            store.currentPlan = nil
                            wc.sendAction("stop")
                        }
                    }
                }
            }
        }
    }

    // MARK: Planera

    private var plannerCard: some View {
        ThemedCard(palette: p) {
            VStack(alignment: .leading, spacing: 18) {
                CardHeader(title: L("Planera"), systemImage: "slider.horizontal.3", palette: p)

                // Start-läge
                VStack(alignment: .leading, spacing: 10) {
                    Text(L("START"))
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(p.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(StartMode.allCases) { mode in
                            ThemeChip(title: mode.title, selected: startMode == mode, palette: p) {
                                withAnimation(.easeInOut(duration: 0.2)) { startMode = mode }
                            }
                        }
                    }

                    switch startMode {
                    case .now:
                        LabeledRow(title: L("Startar"), systemImage: "bolt.fill", palette: p) {
                            Text(Date().formattedTimeSV())
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(p.accent)
                        }
                    case .manual:
                        LabeledRow(title: L("Starttid"), systemImage: "clock.fill", palette: p) {
                            DatePicker("", selection: $manualStart, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .tint(p.accent)
                        }
                    case .autoHK:
                        HStack(spacing: 10) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(p.accent)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(hk.lastDetectedSleepStart == nil ? L("Ingen detektion än") : L("Senaste insomning"))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(p.text)
                                if let d = hk.lastDetectedSleepStart {
                                    Text(d.formattedDateTimeSV())
                                        .font(.system(size: 12))
                                        .foregroundStyle(p.textSecondary)
                                }
                            }
                            Spacer(minLength: 8)
                            Button {
                                Task { await autoDetect() }
                            } label: {
                                if isAutoDetecting {
                                    ProgressView().scaleEffect(0.9)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .tint(p.accent)
                            .disabled(isAutoDetecting)
                        }
                    }
                }

                divider

                // Sömnlängd
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(L("SÖMNLÄNGD"))
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(p.textSecondary)
                        Spacer(minLength: 8)
                        Text(durationSeconds.asHoursMinutesSV())
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(p.accent)
                    }

                    HStack(spacing: 8) {
                        ForEach(Preset.allCases) { item in
                            ThemeChip(
                                title: item.rawValue,
                                selected: !useCustom && preset == item,
                                palette: p
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    useCustom = false
                                    presetRaw = item.rawValue
                                }
                            }
                        }
                        ThemeChip(title: L("Egen"), selected: useCustom, palette: p) {
                            withAnimation(.easeInOut(duration: 0.2)) { useCustom = true }
                        }
                    }

                    if useCustom {
                        SliderRow(
                            title: L("Timmar"),
                            valueText: String(format: "%.1f h", customHours),
                            value: $customHours,
                            range: 1...12,
                            step: 0.5,
                            palette: p
                        )
                    }
                }

                divider

                // Smart fönster
                VStack(alignment: .leading, spacing: 16) {
                    SliderRow(
                        title: L("Smart fönster"),
                        valueText: "\(Int(smartWindowMinutes)) min",
                        value: $smartWindowMinutes,
                        range: 0...60,
                        step: 5,
                        palette: p
                    )

                    SliderRow(
                        title: L("Steg i fönstret"),
                        valueText: "\(Int(windowStepMinutes)) min",
                        value: $windowStepMinutes,
                        range: 1...15,
                        step: 1,
                        palette: p
                    )

                    Text(L("Larmet väcker dig någonstans i fönstret före måltiden — ju mindre steg, desto tätare koll."))
                        .font(.system(size: 12))
                        .foregroundStyle(p.textSecondary)
                }

                divider

                // Snooze + etikett
                VStack(alignment: .leading, spacing: 10) {
                    Text(L("SNOOZE"))
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(p.textSecondary)

                    HStack(spacing: 8) {
                        ForEach([3, 5, 7, 9, 10, 15], id: \.self) { v in
                            ThemeChip(title: L("%d min", v), selected: snoozeMinutes == v, palette: p) {
                                withAnimation(.easeInOut(duration: 0.2)) { snoozeMinutes = v }
                            }
                        }
                    }
                }

                ThemedField(title: L("Etikett"), text: $label, palette: p)
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(p.stroke)
            .frame(height: 1)
    }

    // MARK: Klocka

    private var watchCard: some View {
        ThemedCard(palette: p) {
            VStack(alignment: .leading, spacing: 14) {
                CardHeader(title: L("Apple Watch"), systemImage: "applewatch", palette: p)

                VStack(spacing: 12) {
                    LabeledRow(title: L("Parad"), systemImage: "link", palette: p) {
                        statusIcon(wc.isPaired)
                    }
                    LabeledRow(title: L("Klockapp installerad"), systemImage: "square.and.arrow.down.on.square", palette: p) {
                        // WCSession-flaggan är opålitlig: den uppdateras bara vid aktivering.
                        // Har klockan hört av sig någon gång ÄR appen installerad.
                        statusIcon(wc.watchAppConfirmedInstalled)
                    }
                    LabeledRow(title: L("Nåbar nu"), systemImage: "dot.radiowaves.left.and.right", palette: p) {
                        // isReachable är bara sant medan klockappen är öppen i förgrunden —
                        // en stängd app är inte ett fel, visa senaste kontakt i stället.
                        if wc.isReachable {
                            statusIcon(true)
                        } else if let contact = wc.lastWatchContact {
                            Text(L("i bakgrunden · %@", contact.formattedTimeSV()))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(p.textSecondary)
                        } else {
                            statusIcon(false)
                        }
                    }
                }

                SecondaryButton(title: L("Hämta plan från klockan"), systemImage: "arrow.down.circle.fill", palette: p) {
                    wc.requestPlanFromWatch()
                }

                if let msg = wc.lastMessage {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundStyle(p.textSecondary)
                }
            }
        }
    }

    private func statusIcon(_ ok: Bool) -> some View {
        Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(ok ? p.success : p.textSecondary)
    }

    private func errorLine(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold))
            Text(text).font(.system(size: 12, weight: .medium)).multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color.opacity(0.16)))
        .foregroundStyle(color)
    }

    // MARK: Logik

    private func autoDetect() async {
        isAutoDetecting = true
        defer { isAutoDetecting = false }
        if !hk.authorized {
            await hk.requestAuthorization()
        }
        _ = await hk.detectRecentSleepStart()
    }

    private func startSleep() async {
        if scheduler.authorizationStatus == .notDetermined {
            await scheduler.requestAuthorization()
        }

        var start = Date()
        switch startMode {
        case .now:
            start = Date()
        case .manual:
            // Dagens datum + valt klockslag
            let cal = Calendar.current
            let now = Date()
            let hm = cal.dateComponents([.hour, .minute], from: manualStart)
            start = cal.date(
                bySettingHour: hm.hour ?? cal.component(.hour, from: now),
                minute: hm.minute ?? cal.component(.minute, from: now),
                second: 0,
                of: now
            ) ?? now
            // Ett valt klockslag som redan passerat gäller nästa dygn.
            if start < now {
                start = cal.date(byAdding: .day, value: 1, to: start) ?? now
            }
        case .autoHK:
            if !hk.authorized { await hk.requestAuthorization() }
            let detected = await hk.detectRecentSleepStart()
            start = detected ?? Date()
        }

        var plan = AlarmPlan.make(
            sleepStart: start,
            durationSeconds: durationSeconds,
            smartWindowSeconds: smartWindowMinutes * 60,
            windowStepSeconds: windowStepMinutes * 60,
            snoozeMinutes: snoozeMinutes,
            label: label.isEmpty ? L("Sömn-larm") : label
        )
        plan.notifier = "phone"
        store.currentPlan = plan
        store.addSession(SleepSession(
            id: UUID(),
            startedAt: start,
            plannedDurationSeconds: durationSeconds,
            smartWindowSeconds: smartWindowMinutes * 60,
            snoozeMinutes: snoozeMinutes,
            label: plan.label
        ))

        await scheduler.schedule(plan: plan)
        // Riktigt larm (AlarmKit) på måltiden — ringer tills du stoppar, även i tyst läge/Fokus.
        await phoneAlarms.schedule(for: plan)

        // Synka planen till klockan (den schemalägger sina egna notiser).
        wc.sendPlan(plan)
    }
}