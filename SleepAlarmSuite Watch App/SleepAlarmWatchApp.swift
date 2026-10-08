import SwiftUI
import UserNotifications
import WatchKit

// Visar banner+ljud även när appen är i förgrunden (annars blir notisen tyst).
final class WatchNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

@main
struct SleepAlarmWatchApp: App {
    // Systemet startar om appen i bakgrunden för ett schemalagt larm och anropar
    // handle(_:) på appdelegaten — utan delegat avslutas sessionen utan att ringa.
    @WKApplicationDelegateAdaptor(WatchExtensionDelegate.self) private var appDelegate

    @StateObject private var store = AlarmStore()
    @StateObject private var scheduler = AlarmScheduler()
    @StateObject private var hk = HealthKitSleepManager()
    @StateObject private var wc = WatchConnectivityManager()

    @Environment(\.scenePhase) private var scenePhase
    private let notificationDelegate = WatchNotificationDelegate()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(scheduler)
                .environmentObject(hk)
                .environmentObject(wc)
                .onAppear {
                    UNUserNotificationCenter.current().delegate = notificationDelegate
                    scheduler.refreshAuthStatus()
                    wc.refreshStatus()
                    cleanupPassedPlan()
                    WatchAlarmRinger.shared.schedulePendingIfPossible()
                    wc.planProvider = { [weak store] in store?.currentPlan }
                    wc.onRemotePlan = { [weak store, weak scheduler] plan in
                        guard let store, let scheduler else { return }
                        store.applyRemotePlan(plan, scheduler: scheduler)
                    }
                    wc.onRemoteAction = { [weak store, weak scheduler] action in
                        guard let store, let scheduler else { return }
                        if action == "stop" {
                            store.applyRemoteStop(scheduler: scheduler)
                        }
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        cleanupPassedPlan()
                        // watchOS tillåter bara start(at:) medan appen är aktiv.
                        WatchAlarmRinger.shared.schedulePendingIfPossible()
                    }
                }
        }
    }

    /// Rensa passerade planer + deras notiser och klocklarm när appen blir aktiv.
    private func cleanupPassedPlan() {
        guard let plan = store.currentPlan,
              plan.lastFireDate < Date().addingTimeInterval(-3600) else { return }
        store.currentPlan = nil
        WatchAlarmRinger.shared.cancel()
        Task { await scheduler.cancelLocalNotifications() }
    }
}
