import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: AlarmStore
    @ObservedObject private var theme = ThemeManager.shared

    private var p: ThemePalette { theme.palette }
    private var stats: (count: Int, avgHours: Double, last7AvgHours: Double) { store.stats() }
    private var chartItems: [SleepSession] { Array(store.history.prefix(14)).reversed() }

    /// X-domänen får luft i kanterna, annars klipps första/sista axel-etiketten.
    private var chartDomain: ClosedRange<Date> {
        let dates = chartItems.map { $0.startedAt }
        guard let first = dates.min(), let last = dates.max() else {
            let now = Date()
            return now.addingTimeInterval(-86400)...now
        }
        return first.addingTimeInterval(-3600 * 8)...last.addingTimeInterval(3600 * 18)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    tiles
                    chartCard
                    historyCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(AuroraBackground(palette: p))
            .navigationTitle("Statistik")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Siffror

    private var tiles: some View {
        HStack(spacing: 12) {
            tile(value: "\(stats.count)", unit: "pass", title: "Loggade", icon: "moon.zzz.fill")
            tile(value: String(format: "%.1f", stats.last7AvgHours), unit: "h", title: "Snitt 7", icon: "chart.line.uptrend.xyaxis")
            tile(value: String(format: "%.1f", stats.avgHours), unit: "h", title: "Snitt allt", icon: "chart.bar.fill")
        }
    }

    private func tile(value: String, unit: String, title: String, icon: String) -> some View {
        ThemedCard(palette: p, padding: 14, radius: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(p.accent)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(p.accentGradient)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(unit)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(p.textSecondary)
                }

                Text(title.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.6)
                    .foregroundStyle(p.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    // MARK: Diagram

    private var chartCard: some View {
        ThemedCard(palette: p) {
            VStack(alignment: .leading, spacing: 16) {
                CardHeader(title: "Planerad sömnlängd", systemImage: "chart.bar.xaxis", palette: p)

                if chartItems.isEmpty {
                    emptyHint("Ingen historik än — starta ett larm först.")
                } else {
                    Chart(chartItems) { item in
                        BarMark(
                            x: .value("Datum", item.startedAt),
                            y: .value("Timmar", item.plannedDurationSeconds / 3600.0)
                        )
                        .foregroundStyle(p.accentGradient)
                        .cornerRadius(5)
                    }
                    .chartYScale(domain: 0...(max(10, (chartItems.map { $0.plannedDurationSeconds / 3600.0 }.max() ?? 8) + 1)))
                    .chartXScale(domain: chartDomain)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                            AxisGridLine().foregroundStyle(p.stroke)
                            AxisTick().foregroundStyle(p.stroke)
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                .foregroundStyle(p.textSecondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine().foregroundStyle(p.stroke)
                            AxisValueLabel().foregroundStyle(p.textSecondary)
                        }
                    }
                    .frame(height: 168)
                }
            }
        }
    }

    // MARK: Historik

    private var historyCard: some View {
        ThemedCard(palette: p) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    CardHeader(title: "Historik", systemImage: "list.bullet.rectangle", palette: p)
                    if !store.history.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { store.clearHistory() }
                        } label: {
                            Text("Rensa")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(p.danger.opacity(0.16)))
                                .foregroundStyle(p.danger)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if store.history.isEmpty {
                    emptyHint("Ingen historik än.")
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.history.prefix(20)) { item in
                            historyRow(item)
                        }
                    }
                }
            }
        }
    }

    private func historyRow(_ item: SleepSession) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(p.chipFill)
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(p.accent)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(p.text)
                    .lineLimit(1)
                Text("\(item.startedAt.formattedDateTimeSV()) • \(item.plannedDurationSeconds.asHoursMinutesSV())")
                    .font(.system(size: 12))
                    .foregroundStyle(p.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 3) {
                Text(item.plannedWakeTarget.formattedTimeSV())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(p.accent)
                Text("väckning")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(p.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.fieldFill))
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(p.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}