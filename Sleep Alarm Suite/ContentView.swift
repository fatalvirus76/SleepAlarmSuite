import SwiftUI
import UserNotifications

struct ContentView: View {
    @EnvironmentObject private var store: AlarmStore
    @EnvironmentObject private var scheduler: AlarmScheduler
    @EnvironmentObject private var hk: HealthKitSleepManager
    @EnvironmentObject private var wc: PhoneConnectivityManager

    @AppStorage("useCustom") private var useCustom: Bool = false
    @AppStorage("presetRaw") private var presetRaw: String = Preset.h8.rawValue
    @AppStorage("customHours") private var customHours: Double = 8.0

    @AppStorage("smartWindowMinutes") private var smartWindowMinutes: Double = 20
    @AppStorage("windowStepMinutes") private var windowStepMinutes: Double = 5
    @AppStorage("snoozeMinutes") private var snoozeMinutes: Int = 9
    @AppStorage("label") private var label: String = "Sömn-larm"

    @State private var startMode: StartMode = .now
    @State private var manualStart: Date = Date()
    @State private var isAutoDetecting: Bool = false
    @State private var showSetupHint = false

    enum StartMode: String, CaseIterable, Identifiable {
        case now = "Nu"
        case manual = "Manuellt"
        case autoHK = "Auto (HealthKit)"
        var id: String { rawValue }
    }

    private var preset: Preset { Preset(rawValue: presetRaw) ?? .h8 }

    private var durationSeconds: TimeInterval {
        (useCustom ? customHours * 3600 : preset.seconds)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    statusRows
                }

                Section("Planera") {
                    Picker("Start", selection: $startMode) {
                        ForEach(StartMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch startMode {
                    case .now:
                        Text("Start = nu (\(Date().formattedTimeSV()))")
                            .font(.footnote).foregroundStyle(.secondary)
                    case .manual:
                        DatePicker("Tid", selection: $manualStart, displayedComponents: [.hourAndMinute])
                    case .autoHK:
                        autoHKRow
                    }

                    Toggle("Egen längd", isOn: $useCustom)

                    if useCustom {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Timmar: \(customHours, specifier: "%.1f")")
                                .font(.footnote).foregroundStyle(.secondary)
                            Slider(value: $customHours, in: 4...12, step: 0.5)
                        }
                    } else {
                        Picker("Preset", selection: $presetRaw) {
                            ForEach(Preset.allCases) { p in
                                Text(p.title).tag(p.rawValue)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Smart fönster: \(Int(smartWindowMinutes)) min • steg \(Int(windowStepMinutes)) min")
                            .font(.footnote).foregroundStyle(.secondary)
                        Slider(value: $smartWindowMinutes, in: 0...60, step: 5)
                        Slider(value: $windowStepMinutes, in: 1...15, step: 1)
                    }

                    Picker("Snooze", selection: $snoozeMinutes) {
                        ForEach([3,5,7,9,10,15], id: \.self) { v in
                            Text("\(v) min").tag(v)
                        }
                    }

                    TextField("Etikett", text: $label)
                }

                Section {
                    Button {
                        Task { await startSleep() }
                    } label: {
                        Label("Starta sömn-larm", systemImage: "bed.double.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let plan = store.currentPlan, plan.enabled {
                        Button {
                            Task {
                                let snoozed = await scheduler.snooze(plan: plan)
                                store.currentPlan = snoozed
                                await scheduler.schedule(plan: snoozed)
                                wc.sendPlan(snoozed)
                            }
                        } label: {
                            Label("Snooze nu (+\(plan.snoozeMinutes) min)", systemImage: "clock.arrow.circlepath")
                                .frame(maxWidth: .infinity)
                        }

                        Button(role: .destructive) {
                            Task {
                                await scheduler.clearPendingForPrefix()
                                store.currentPlan = nil
                                wc.sendAction("stop")
                            }
                        } label: {
                            Label("Stoppa larm", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }

                Section("Klocka") {
                    watchRows
                }
            }
            .navigationTitle("Sleep Alarm")
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusRows: some View {
        if scheduler.authorizationStatus == .notDetermined {
            Button {
                Task { await scheduler.requestAuthorization() }
            } label: {
                Label("Aktivera notiser", systemImage: "bell.badge")
            }
        } else if scheduler.authorizationStatus == .denied {
            Label("Notiser är avstängda — aktivera i Inställningar.", systemImage: "bell.slash")
                .foregroundStyle(.red)
                .font(.footnote)
        }

        if let plan = store.currentPlan, plan.enabled {
            VStack(alignment: .leading, spacing: 4) {
                Text("Aktivt: \(plan.label)").font(.subheadline)
                Text("Start: \(plan.sleepStart.formattedDateTimeSV())").font(.caption).foregroundStyle(.secondary)
                Text("Mål: \(plan.targetDurationSeconds.asHoursMinutesSV())").font(.caption).foregroundStyle(.secondary)
                if plan.smartWindowSeconds > 0 {
                    Text("Fönster: \(TimeInterval(plan.smartWindowSeconds).asHoursMinutesSV()) • steg \(Int(plan.windowStepSeconds/60)) min")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text("Väcker senast: \(plan.lastFireDate.formattedDateTimeSV())")
                    .font(.subheadline).fontWeight(.semibold)
            }
        } else {
            Text("Inget aktivt larm.").foregroundStyle(.secondary)
        }

        if let err = scheduler.lastError {
            Text(err).font(.caption).foregroundStyle(.red)
        }
        if let err = hk.lastError {
            Text(err).font(.caption).foregroundStyle(.orange)
        }
    }

    private var autoHKRow: some View {
        HStack(spacing: 10) {
            if let d = hk.lastDetectedSleepStart {
                Text("Senast: \(d.formattedTimeSV())")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Text("Ingen detektion än")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await autoDetect() }
            } label: {
                if isAutoDetecting {
                    ProgressView().scaleEffect(0.9)
                } else {
                    Image(systemName: "wand.and.stars")
                }
            }
            .disabled(isAutoDetecting)
        }
    }

    @ViewBuilder
    private var watchRows: some View {
        HStack {
            Label("Parad", systemImage: "applewatch")
            Spacer()
            Image(systemName: wc.isPaired ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(wc.isPaired ? Color.green : Color.secondary)
        }
        HStack {
            Label("Klockapp installerad", systemImage: "square.and.arrow.down.on.square")
            Spacer()
            Image(systemName: wc.isWatchAppInstalled ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(wc.isWatchAppInstalled ? Color.green : Color.secondary)
        }
        HStack {
            Label("Nåbar", systemImage: "dot.radiowaves.left.and.right")
            Spacer()
            Image(systemName: wc.isReachable ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(wc.isReachable ? Color.green : Color.secondary)
        }
        Button {
            wc.requestPlanFromWatch()
        } label: {
            Label("Hämta plan från klockan", systemImage: "arrow.down.circle")
        }
        if let msg = wc.lastMessage {
            Text(msg).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Åtgärder

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

        // Välj starttid
        var start = Date()
        switch startMode {
        case .now:
            start = Date()
        case .manual:
            // Dagens datum + valt klockslag
            let cal = Calendar.current
            let now = Date()
            let hm = cal.dateComponents([.hour,.minute], from: manualStart)
            start = cal.date(bySettingHour: hm.hour ?? cal.component(.hour, from: now),
                             minute: hm.minute ?? cal.component(.minute, from: now),
                             second: 0,
                             of: now) ?? now
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

        await scheduler.schedule(plan: plan)

        // Synka planen till klockan (den schemalägger sina egna notiser).
        wc.sendPlan(plan)
    }
}
