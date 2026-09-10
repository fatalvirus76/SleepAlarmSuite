import Foundation
import Combine

// Speglar Watch App:ens AlarmStore (samma payloads) + fjärr-tillämpning från klockan.
@MainActor
final class AlarmStore: ObservableObject {
    @Published var currentPlan: AlarmPlan? { didSet { save() } }
    @Published var history: [SleepSession] = [] { didSet { save() } }

    private let key = "sleep_alarm_store_v2"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func addSession(_ session: SleepSession) {
        history.insert(session, at: 0)
        if history.count > 60 { history = Array(history.prefix(60)) }
    }

    func clearHistory() { history.removeAll() }

    /// Tillämpar plan som tagits emot från klockan (klockan schemalägger sina notiser,
    /// vi schemalägger våra — båda avbryter sina egna via cancelLocalNotifications).
    func applyRemotePlan(_ plan: AlarmPlan, scheduler: AlarmScheduler) {
        currentPlan = plan
        Task { await scheduler.cancelLocalNotifications() }
    }

    /// Stopp-kommando från klockan: rensa lokalt + lokala notiser.
    func applyRemoteStop(scheduler: AlarmScheduler) {
        currentPlan = nil
        Task { await scheduler.cancelLocalNotifications() }
    }

    func stats() -> (count: Int, avgHours: Double, last7AvgHours: Double) {
        let durations = history.map { $0.plannedDurationSeconds / 3600.0 }
        let avg = durations.isEmpty ? 0 : durations.reduce(0,+) / Double(durations.count)
        let last7 = Array(durations.prefix(7))
        let last7avg = last7.isEmpty ? 0 : last7.reduce(0,+) / Double(last7.count)
        return (durations.count, avg, last7avg)
    }

    private func load() {
        guard let data = defaults.data(forKey: key) else { return }
        do {
            let decoded = try JSONDecoder().decode(StorePayload.self, from: data)
            self.currentPlan = decoded.currentPlan
            self.history = decoded.history
        } catch {
            self.currentPlan = nil
            self.history = []
        }
    }

    private func save() {
        do {
            let payload = StorePayload(currentPlan: currentPlan, history: history)
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: key)
        } catch {
            // ignore
        }
    }

    private struct StorePayload: Codable {
        var currentPlan: AlarmPlan?
        var history: [SleepSession]
    }
}
