import Foundation

struct AlarmPlan: Codable, Identifiable, Equatable {
    let id: UUID
    var createdAt: Date
    var sleepStart: Date
    var targetDurationSeconds: TimeInterval
    var smartWindowSeconds: TimeInterval
    var windowStepSeconds: TimeInterval
    var firstFireDate: Date
    var lastFireDate: Date
    var snoozeMinutes: Int
    var label: String
    var enabled: Bool

    static func make(
        sleepStart: Date,
        durationSeconds: TimeInterval,
        smartWindowSeconds: TimeInterval,
        windowStepSeconds: TimeInterval,
        snoozeMinutes: Int,
        label: String
    ) -> AlarmPlan {
        let target = sleepStart.addingTimeInterval(durationSeconds)
        let first = target.addingTimeInterval(-smartWindowSeconds)
        let last = target
        return AlarmPlan(
            id: UUID(),
            createdAt: Date(),
            sleepStart: sleepStart,
            targetDurationSeconds: durationSeconds,
            smartWindowSeconds: smartWindowSeconds,
            windowStepSeconds: windowStepSeconds,
            firstFireDate: first,
            lastFireDate: last,
            snoozeMinutes: snoozeMinutes,
            label: label,
            enabled: true
        )
    }
}

struct SleepSession: Codable, Identifiable, Equatable {
    let id: UUID
    var startedAt: Date
    var plannedDurationSeconds: TimeInterval
    var smartWindowSeconds: TimeInterval
    var snoozeMinutes: Int
    var label: String

    var plannedWakeTarget: Date { startedAt.addingTimeInterval(plannedDurationSeconds) }
}

enum Preset: String, CaseIterable, Identifiable {
    case h6 = "6h"
    case h7_5 = "7.5h"
    case h8 = "8h"
    case h9 = "9h"

    var id: String { rawValue }

    var seconds: TimeInterval {
        switch self {
        case .h6: return 6 * 3600
        case .h7_5: return 7.5 * 3600
        case .h8: return 8 * 3600
        case .h9: return 9 * 3600
        }
    }

    var title: String {
        switch self {
        case .h6: return "6 timmar"
        case .h7_5: return "7.5 timmar"
        case .h8: return "8 timmar"
        case .h9: return "9 timmar"
        }
    }
}

extension Date {
    func formattedTimeSV() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "sv_SE")
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }

    func formattedDateTimeSV() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "sv_SE")
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: self)
    }
}

extension TimeInterval {
    func asHoursMinutesSV() -> String {
        let totalMins = Int(self / 60)
        let h = totalMins / 60
        let m = totalMins % 60
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}
