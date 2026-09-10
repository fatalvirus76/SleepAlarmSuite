import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var scheduler: AlarmScheduler
    @EnvironmentObject private var hk: HealthKitSleepManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Inställningar")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notiser").font(.headline)
                    Text("Behövs för att väcka med haptik/notis.")
                        .font(.caption2).foregroundStyle(.secondary)

                    Button {
                        Task { await scheduler.requestAuthorization() }
                    } label: {
                        Label("Begär notis-tillstånd", systemImage: "bell")
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.12)))

                VStack(alignment: .leading, spacing: 8) {
                    Text("HealthKit").font(.headline)
                    Text("Används för att försöka hitta senaste insomningstid.")
                        .font(.caption2).foregroundStyle(.secondary)

                    Button {
                        Task { await hk.requestAuthorization() }
                    } label: {
                        Label("Aktivera HealthKit", systemImage: "heart.fill")
                    }

                    if let d = hk.lastDetectedSleepStart {
                        Text("Senast upptäckt sömnstart: \(d.formattedDateTimeSV())")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.10)))
            }
            .padding(.top, 8)
        }
    }
}
