import SwiftUI
import WatchKit

struct RootView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem { Label("Larm", systemImage: "alarm") }

            SettingsView()
                .tabItem { Label("Inställn.", systemImage: "gearshape") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
        }
    }
}
