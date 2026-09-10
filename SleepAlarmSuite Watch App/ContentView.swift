import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject private var store: AlarmStore
    @EnvironmentObject private var scheduler: AlarmScheduler
    @EnvironmentObject private var hk: HealthKitSleepManager
    @EnvironmentObject private var wc: WatchConnectivityManager

    @AppStorage("useCustom", store: AppConfig.defaults) private var useCustom: Bool = false
    @AppStorage("presetRaw", store: AppConfig.defaults) private var presetRaw: String = Preset.h8.rawValue
    @AppStorage("customHours", store: AppConfig.defaults) private var customHours: Double = 8.0

    @AppStorage("smartWindowMinutes", store: AppConfig.defaults) private var smartWindowMinutes: Double = 20
    @AppStorage("windowStepMinutes", store: AppConfig.defaults) private var windowStepMinutes: Double = 5
    @AppStorage("snoozeMinutes", store: AppConfig.defaults) private var snoozeMinutes: Int = 9
    @AppStorage("label", store: AppConfig.defaults) private var label: String = "Sömn-larm"

    @State private var startMode: StartMode = .now
    @State private var manualStart: Date = Date()
    @State private var isAutoDetecting: Bool = false

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
        ScrollView {
            VStack(spacing: 10) {
                header
                statusCard
                planCard
                actionsCard
            }
            .padding(.top, 6)
        }
        .navigationTitle("Sleep Alarm")
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Sleep Alarm")
                .font(.headline)
            Text("Sätt larm efter insomning")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Status").font(.headline)
                Spacer()
                Text(scheduler.authorizationStatus == .authorized || scheduler.authorizationStatus == .provisional ? "Notiser ON" : "Notiser OFF")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill((scheduler.authorizationStatus == .authorized || scheduler.authorizationStatus == .provisional) ? Color.green.opacity(0.25) : Color.red.opacity(0.25)))
            }

            if let plan = store.currentPlan, plan.enabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aktivt: \(plan.label)").font(.subheadline)
                    Text("Start: \(plan.sleepStart.formattedDateTimeSV())").font(.caption2).foregroundStyle(.secondary)
                    Text("Mål: \(plan.targetDurationSeconds.asHoursMinutesSV())").font(.caption2).foregroundStyle(.secondary)
                    if plan.smartWindowSeconds > 0 {
                        Text("Fönster: \(TimeInterval(plan.smartWindowSeconds).asHoursMinutesSV()) • steg \(Int(plan.windowStepSeconds/60)) min")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Text("Väcker senast: \(plan.lastFireDate.formattedDateTimeSV())")
                        .font(.caption).fontWeight(.semibold)
                }
            } else {
                Text("Inget aktivt larm.").font(.subheadline).foregroundStyle(.secondary)
            }

            if let err = scheduler.lastError {
                Text(err).font(.caption2).foregroundStyle(.red)
            }
            if let err = hk.lastError {
                Text(err).font(.caption2).foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(white: 0.12)))
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Planera").font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Label").font(.caption2).foregroundStyle(.secondary)
                TextField("Sömn-larm", text: $label)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Start").font(.caption2).foregroundStyle(.secondary)
                Picker("", selection: $startMode) {
                    ForEach(StartMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                #if os(watchOS)
                .pickerStyle(.wheel)
                #else
                .pickerStyle(.segmented)
                #endif

                switch startMode {
                case .now:
                    Text("Start = nu (\(Date().formattedTimeSV()))")
                        .font(.caption2).foregroundStyle(.secondary)
                case .manual:
                    HStack {
                        Text("Tid").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        DatePicker("", selection: $manualStart, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                    }
                case .autoHK:
                    HStack(spacing: 8) {
                        if let d = hk.lastDetectedSleepStart {
                            Text("Senast: \(d.formattedTimeSV())").font(.caption2).foregroundStyle(.secondary)
                        } else {
                            Text("Ingen detektion än").font(.caption2).foregroundStyle(.secondary)
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
                    }
                }
            }

            Divider().opacity(0.4)

            Toggle("Egen längd", isOn: $useCustom)

            if useCustom {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Timmar: \(customHours, specifier: "%.1f")").font(.caption2).foregroundStyle(.secondary)
                    Slider(value: $customHours, in: 4...12, step: 0.5)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Preset").font(.caption2).foregroundStyle(.secondary)
                    Picker("Preset", selection: $presetRaw) {
                        ForEach(Preset.allCases) { p in
                            Text(p.title).tag(p.rawValue)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Smart fönster (min): \(Int(smartWindowMinutes))").font(.caption2).foregroundStyle(.secondary)
                Slider(value: $smartWindowMinutes, in: 0...60, step: 5)

                Text("Steg i fönster (min): \(Int(windowStepMinutes))").font(.caption2).foregroundStyle(.secondary)
                Slider(value: $windowStepMinutes, in: 1...15, step: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Snooze").font(.caption2).foregroundStyle(.secondary)
                Picker("Snooze", selection: $snoozeMinutes) {
                    ForEach([3,5,7,9,10,15], id: \.self) { v in
                        Text("\(v) min").tag(v)
                    }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(white: 0.10)))
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Åtgärder").font(.headline)

            if scheduler.authorizationStatus != .authorized && scheduler.authorizationStatus != .provisional {
                Button {
                    Task { await scheduler.requestAuthorization() }
                } label: {
                    Label("Aktivera notiser", systemImage: "bell.badge")
                }
            }

            Button {
                Task { await startSleep() }
            } label: {
                Label("Starta sömn-larm", systemImage: "bed.double.fill")
            }
            .buttonStyle(.borderedProminent)

            HStack {
                Button {
                    WKInterfaceDevice.current().play(.notification)
                } label: {
                    Label("Testa haptik", systemImage: "waveform.path")
                }

                Button {
                    Task {
                        await scheduler.clearPendingForPrefix()
                        store.currentPlan = nil
                        wc.sendAction("stop")
                        WKInterfaceDevice.current().play(.click)
                    }
                } label: {
                    Label("Stoppa", systemImage: "stop.fill")
                }
                .tint(.red)
            }

            if let plan = store.currentPlan, plan.enabled {
                Button {
                    Task {
                        let snoozed = await scheduler.snooze(plan: plan)
                        store.currentPlan = snoozed
                        await scheduler.schedule(plan: snoozed)
                        wc.sendPlan(snoozed)
                        WKInterfaceDevice.current().play(.directionDown)
                    }
                } label: {
                    Label("Snooze nu (+\(snoozeMinutes) min)", systemImage: "clock.arrow.circlepath")
                }
            }

            if let msg = wc.lastMessage {
                Text(msg).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(white: 0.12)))
        .padding(.bottom, 10)
    }

    private func autoDetect() async {
        isAutoDetecting = true
        defer { isAutoDetecting = false }
        if !hk.authorized {
            await hk.requestAuthorization()
        }
        _ = await hk.detectRecentSleepStart()
    }

    private func startSleep() async {
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

        WKInterfaceDevice.current().play(.success)
        await scheduler.schedule(plan: plan)

        // Synka planen till iPhone (den schemalägger sina egna notiser).
        wc.sendPlan(plan)
    }
}
