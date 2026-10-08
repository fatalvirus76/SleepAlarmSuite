import SwiftUI
import UserNotifications

// Visar banner+ljud även när appen är i förgrunden (annars blir notisen tyst).
final class PhoneNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

@main
struct Sleep_Alarm_SuiteApp: App {
    @StateObject private var store = AlarmStore()
    @StateObject private var scheduler = AlarmScheduler()
    @StateObject private var hk = HealthKitSleepManager()
    @StateObject private var wc = PhoneConnectivityManager()
    @StateObject private var phoneAlarms = PhoneAlarmManager()

    @Environment(\.scenePhase) private var scenePhase
    private let notificationDelegate = PhoneNotificationDelegate()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(scheduler)
                .environmentObject(hk)
                .environmentObject(wc)
                .environmentObject(phoneAlarms)
                .onAppear {
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                    scheduler.refreshAuthStatus()
                    phoneAlarms.refreshAuthorization()
                    wc.refreshStatus()
                    cleanupPassedPlan()
                    wc.planProvider = { [weak store] in store?.currentPlan }
                    wc.onRemotePlan = { [weak store, weak scheduler, weak phoneAlarms] plan in
                        guard let store, let scheduler, let phoneAlarms else { return }
                        store.applyRemotePlan(plan, scheduler: scheduler, phoneAlarms: phoneAlarms)
                    }
                    wc.onRemoteAction = { [weak store, weak scheduler, weak phoneAlarms] action in
                        guard let store, let scheduler, let phoneAlarms else { return }
                        if action == "stop" {
                            store.applyRemoteStop(scheduler: scheduler, phoneAlarms: phoneAlarms)
                        }
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        cleanupPassedPlan()
                    }
                }
        }
    }

    /// Rensa passerade planer + deras notiser (och ev. AlarmKit-larm) när appen blir aktiv.
    private func cleanupPassedPlan() {
        guard let plan = store.currentPlan,
              plan.lastFireDate < Date().addingTimeInterval(-3600) else { return }
        phoneAlarms.cancel(for: plan.id)
        store.currentPlan = nil
        Task { await scheduler.cancelLocalNotifications() }
    }
}
