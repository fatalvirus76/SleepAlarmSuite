import WidgetKit
import SwiftUI

struct NextWakeEntry: TimelineEntry {
    let date: Date
    let nextWakeString: String?
}

struct NextWakeProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextWakeEntry {
        NextWakeEntry(date: Date(), nextWakeString: "07:00")
    }

    func getSnapshot(in context: Context, completion: @escaping (NextWakeEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextWakeEntry>) -> Void) {
        let entry = loadEntry()
        // Uppdatera ofta nog för att visa ändringar
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> NextWakeEntry {
        // För att detta ska funka mellan app+widget: sätt App Group och samma suiteName.
        let defaults = AppConfig.defaults
        let str = defaults.string(forKey: "widget_nextWakeString")
        return NextWakeEntry(date: Date(), nextWakeString: str)
    }
}

struct SleepAlarmWidgetView: View {
    var entry: NextWakeProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sleep Alarm")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let s = entry.nextWakeString {
                Text(s)
                    .font(.headline)
            } else {
                Text("—")
                    .font(.headline)
            }
            Text("Nästa väckning")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }
}

struct SleepAlarmWidget: Widget {
    let kind: String = "SleepAlarmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextWakeProvider()) { entry in
            SleepAlarmWidgetView(entry: entry)
        }
        .configurationDisplayName("Sleep Alarm")
        .description("Visar nästa planerade väckning.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
