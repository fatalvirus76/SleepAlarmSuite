import Foundation
import AlarmKit
import SwiftUI
import Combine

// Riktigt larm via AlarmKit (iOS 26+): bryter igenom tyst läge + Fokus och ringer
// tills användaren stoppar — till skillnad från vanliga notiser som bara pingar en gång.
// Notis-schemaläggningen i AlarmScheduler ligger kvar som komplement (smart fönster),
// men AlarmKit-larmet på lastFireDate är det som garanterat väcker.
@MainActor
final class PhoneAlarmManager: ObservableObject {
    struct SleepAlarmMetadata: AlarmMetadata {
        var planID: UUID
    }

    @Published var authorizationState: AlarmManager.AuthorizationState = .notDetermined
    @Published var lastError: String?

    /// UUID:t som AlarmKit-larmet schemaläggs under — alltid planens eget id.
    func schedule(for plan: AlarmPlan) async {
        guard plan.enabled else {
            lastError = L("Planen är avstängd — inget AlarmKit-larm schemalagt.")
            return
        }
        let fireDate = plan.lastFireDate
        guard fireDate > Date() else {
            lastError = L("Tiden %@ har passerat — inget AlarmKit-larm schemalagt.", fireDate.formattedTimeSV())
            return
        }

        do {
            if AlarmManager.shared.authorizationState == .notDetermined {
                _ = try await AlarmManager.shared.requestAuthorization()
            }
            authorizationState = AlarmManager.shared.authorizationState
            guard authorizationState == .authorized else {
                lastError = L("AlarmKit ej auktoriserat — vanliga notiser används som reserv.")
                return
            }

            let snoozeButton = AlarmButton(
                text: LocalizedStringResource("Snooze"),
                textColor: .white,
                systemImageName: "zzz"
            )
            let alert = AlarmPresentation.Alert(
                title: LocalizedStringResource("⏰ \(plan.label)"),
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .countdown
            )
            let attributes = AlarmAttributes(
                presentation: AlarmPresentation(alert: alert),
                metadata: SleepAlarmMetadata(planID: plan.id),
                tintColor: .orange
            )
            let config = AlarmManager.AlarmConfiguration(
                schedule: .fixed(fireDate),
                attributes: attributes
            )
            _ = try await AlarmManager.shared.schedule(id: plan.id, configuration: config)
            lastError = nil
        } catch {
            lastError = "AlarmKit: \(error.localizedDescription)"
        }
    }

    func cancel(for planID: UUID) {
        do {
            try AlarmManager.shared.cancel(id: planID)
        } catch {
            // Larmet fanns kanske inte kvar (t.ex. redan avfyrat) — ignorera.
        }
    }

    func refreshAuthorization() {
        authorizationState = AlarmManager.shared.authorizationState
    }
}
