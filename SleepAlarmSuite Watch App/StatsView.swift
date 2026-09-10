import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: AlarmStore

    var body: some View {
        let s = store.stats()
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Statistik")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sessions: \(s.count)")
                    Text("Snitt (alla): \(s.avgHours, specifier: "%.2f") h")
                    Text("Snitt (senaste 7): \(s.last7AvgHours, specifier: "%.2f") h")
                }
                .font(.subheadline)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.12)))

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Senaste")
                            .font(.headline)
                        Spacer()
                        Button("Rensa") { store.clearHistory() }
                            .font(.caption2)
                    }

                    if store.history.isEmpty {
                        Text("Ingen historik än.")
                            .font(.caption2).foregroundStyle(.secondary)
                    } else {
                        ForEach(store.history.prefix(12)) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label).font(.subheadline)
                                Text("Start \(item.startedAt.formattedTimeSV()) • mål \(item.plannedDurationSeconds.asHoursMinutesSV()) • vakna \(item.plannedWakeTarget.formattedTimeSV())")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            if item.id != store.history.prefix(12).last?.id {
                                Divider().opacity(0.25)
                            }
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.10)))
            }
            .padding(.top, 8)
        }
    }
}
