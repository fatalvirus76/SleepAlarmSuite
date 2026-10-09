import SwiftUI
import WatchKit

struct RootView: View {
    @ObservedObject private var theme = WatchThemeManager.shared
    @ObservedObject private var i18n = I18nManager.shared
    @AppStorage("watchTab", store: AppConfig.defaults) private var tab: Int = 0

    var body: some View {
        TabView(selection: $tab) {
            ContentView()
                .tabItem { Label(L("Larm"), systemImage: "alarm.fill") }
                .tag(0)

            PlanView()
                .tabItem { Label(L("Planera"), systemImage: "slider.horizontal.3") }
                .tag(1)

            StatsView()
                .tabItem { Label(L("Stats"), systemImage: "chart.bar.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label(L("Mer"), systemImage: "ellipsis.circle.fill") }
                .tag(3)
        }
        .tint(theme.palette.accent)
    }
}