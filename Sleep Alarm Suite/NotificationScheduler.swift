import Foundation
import UserNotifications
import Combine

// Speglar Watch App:ens AlarmScheduler — samma notis-identifier-prefix, samma fönsterlogik.
@MainActor
final class AlarmScheduler: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var lastError: String?

    func refreshAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            self.lastError = granted ? nil : "Notiser nekades. Slå på i Inställningar."
            refreshAuthStatus()
        } catch {
            self.lastError = "Kunde inte begära notiser: \(error.localizedDescription)"
            refreshAuthStatus()
        }
    }

    /// Schemalägg flera notiser i smart-fönstret: firstFireDate ... lastFireDate med step.
    func schedule(plan: AlarmPlan) async {
        await clearPendingForPrefix()

        let now = Date().addingTimeInterval(3)
        let start = max(plan.firstFireDate, now)
        let end = max(plan.lastFireDate, start)
        let step = max(plan.windowStepSeconds, 60) // minst 1 minut

        var fireDates: [Date] = []
        var t = start
        while t <= end {
            fireDates.append(t)
            t = t.addingTimeInterval(step)
        }
        if fireDates.isEmpty { fireDates = [end] }

        for (i, date) in fireDates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "⏰ \(plan.label)"
            content.body = fireDates.count > 1
                ? "Väckningsfönster \(i+1)/\(fireDates.count). Öppna appen för snooze/stop."
                : "Dags att vakna! Öppna appen för snooze/stop."
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let request = UNNotificationRequest(
                identifier: AppConfig.notificationPrefix + plan.id.uuidString + ".\(i)",
                content: content,
                trigger: trigger
            )
            do {
                try await UNUserNotificationCenter.current().add(request)
                self.lastError = nil
            } catch {
                self.lastError = "Kunde inte schemalägga: \(error.localizedDescription)"
            }
        }
    }

    func snooze(plan: AlarmPlan) async -> AlarmPlan {
        let newFire = Date().addingTimeInterval(TimeInterval(plan.snoozeMinutes) * 60)
        var copy = plan
        copy.createdAt = Date()
        copy.firstFireDate = newFire
        copy.lastFireDate = newFire
        copy.smartWindowSeconds = 0
        copy.windowStepSeconds = 60
        copy.enabled = true
        return copy
    }

    func clearPendingForPrefix() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let ids = requests.map(\.identifier).filter { $0.hasPrefix(AppConfig.notificationPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeAllDeliveredNotifications()
        self.lastError = nil
    }

    /// Avbryter bara lokala schemalagda notiser (när plan togs emot från andra sidan).
    func cancelLocalNotifications() async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let ids = requests.map(\.identifier).filter { $0.hasPrefix(AppConfig.notificationPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
