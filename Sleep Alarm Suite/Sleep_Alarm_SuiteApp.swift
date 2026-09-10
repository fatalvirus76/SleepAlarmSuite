import SwiftUI

@main
struct Sleep_Alarm_SuiteApp: App {
    @StateObject private var store = AlarmStore()
    @StateObject private var scheduler = AlarmScheduler()
    @StateObject private var hk = HealthKitSleepManager()
    @StateObject private var wc = PhoneConnectivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(scheduler)
                .environmentObject(hk)
                .environmentObject(wc)
                .onAppear {
                    scheduler.refreshAuthStatus()
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
        }
    }
}
