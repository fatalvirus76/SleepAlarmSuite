import SwiftUI

// Flik 3: Statistik — siffror, enkel stapelgraf och historik.
struct StatsView: View {
    @EnvironmentObject private var store: AlarmStore
    @ObservedObject private var theme = WatchThemeManager.shared

    private var p: WatchPalette { theme.palette }
    private var stats: (count: Int, avgHours: Double, last7AvgHours: Double) { store.stats() }
    private var chartItems: [SleepSession] { Array(store.history.prefix(10)).reversed() }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                numbersCard
                chartCard
                historyCard
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 14)
        }
        .background(WatchBackground(palette: p))
    }

    // MARK: Siffror

    private var numbersCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                WatchSectionTitle(title: "Översikt", systemImage: "chart.bar.fill", palette: p)

                bigRow(value: "\(stats.count)", unit: "pass", title: "Loggade")
                bigRow(value: String(format: "%.1f", stats.last7AvgHours), unit: "h", title: "Snitt senaste 7")
                bigRow(value: String(format: "%.1f", stats.avgHours), unit: "h", title: "Snitt alla")
            }
        }
    }

    private func bigRow(value: String, unit: String, title: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(p.accentGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(unit)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(p.textSecondary)

            Spacer(minLength: 4)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(p.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: Stapelgraf

    private var chartCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                WatchSectionTitle(title: "Senaste passen", systemImage: "chart.line.uptrend.xyaxis", palette: p)

                if chartItems.isEmpty {
                    Text("Ingen historik än.")
                        .font(.system(size: 13))
                        .foregroundStyle(p.textSecondary)
                } else {
                    GeometryReader { geo in
                        let maxHours = max(10.0, chartItems.map { $0.plannedDurationSeconds / 3600.0 }.max() ?? 8)
                        let barWidth = max(6, (geo.size.width - CGFloat(chartItems.count - 1) * 4) / CGFloat(max(chartItems.count, 1)))
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(chartItems) { item in
                                let hours = item.plannedDurationSeconds / 3600.0
                                let frac = min(max(hours / maxHours, 0.06), 1)
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(p.accentGradient)
                                    .frame(width: barWidth, height: geo.size.height * frac)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    }
                    .frame(height: 74)

                    Text("Timmar per pass (planerad sömnlängd)")
                        .font(.system(size: 11))
                        .foregroundStyle(p.textSecondary)
                }
            }
        }
    }

    // MARK: Historik

    private var historyCard: some View {
        WatchCard(palette: p, padding: 12) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    WatchSectionTitle(title: "Historik", systemImage: "list.bullet", palette: p)
                    if !store.history.isEmpty {
                        Button {
                            store.clearHistory()
                        } label: {
                            Text("Rensa")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(p.dangerSafe.opacity(0.20)))
                                .foregroundStyle(p.dangerSafe)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if store.history.isEmpty {
                    Text("Ingen historik än.")
                        .font(.system(size: 13))
                        .foregroundStyle(p.textSecondary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(store.history.prefix(10)) { item in
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.label)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(p.text)
                                        .lineLimit(1)
                                    Text("\(item.startedAt.formattedTimeSV()) • \(item.plannedDurationSeconds.asHoursMinutesSV())")
                                        .font(.system(size: 11))
                                        .foregroundStyle(p.textSecondary)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 4)
                                Text(item.plannedWakeTarget.formattedTimeSV())
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(p.accent)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(p.fieldFill))
                        }
                    }
                }
            }
        }
    }
}