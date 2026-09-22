import SwiftUI
import WatchKit

struct RootView: View {
    @ObservedObject private var theme = WatchThemeManager.shared
    @AppStorage("watchTab", store: AppConfig.defaults) private var tab: Int = 0

    var body: some View {
        TabView(selection: $tab) {
            ContentView()
                .tabItem { Label("Larm", systemImage: "alarm.fill") }
                .tag(0)

            PlanView()
                .tabItem { Label("Planera", systemImage: "slider.horizontal.3") }
                .tag(1)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Mer", systemImage: "ellipsis.circle.fill") }
                .tag(3)
        }
        .tint(theme.palette.accent)
    }
}