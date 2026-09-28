import Foundation
@preconcurrency import HealthKit
import Combine

// Speglar Watch App:ens HealthKitSleepManager — används för "Auto (HealthKit)"-start.
@MainActor
final class HealthKitSleepManager: ObservableObject {
    @Published var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    @Published var authorized: Bool = false
    @Published var lastError: String?
    @Published var lastDetectedSleepStart: Date?

    private let store = HKHealthStore()

    private var sleepType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    }

    func requestAuthorization() async {
        guard isAvailable, let type = sleepType else {
            lastError = "HealthKit är inte tillgängligt på den här enheten."
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: [type])
            authorized = true
            lastError = nil
        } catch {
            authorized = false
            lastError = "HealthKit permission misslyckades: \(error.localizedDescription)"
        }
    }

    /// Försök hitta senaste "asleep" start. Sleep-samples skrivs ofta i efterhand — best effort.
    func detectRecentSleepStart(maxLookbackHours: Double = 12) async -> Date? {
        guard authorized, let type = sleepType else { return nil }

        let end = Date()
        let start = end.addingTimeInterval(-maxLookbackHours * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictEndDate)

        let (detected, errMsg): (Date?, String?) = await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 50, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    cont.resume(returning: (nil, "HealthKit query error: \(error.localizedDescription)"))
                    return
                }

                let cats = (samples as? [HKCategorySample]) ?? []

                // Senaste sample som representerar "asleep" (iOS 16+: asleepUnspecified/Core/Deep/REM).
                let asleepSample = cats.first(where: { sample in
                    if let v = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                        return v == .asleepUnspecified || v == .asleepCore || v == .asleepDeep || v == .asleepREM
                    }
                    return false
                })

                cont.resume(returning: (asleepSample?.startDate, nil))
            }

            HKHealthStore().execute(query)
        }

        self.lastDetectedSleepStart = detected
        self.lastError = errMsg
        // Avvisa för gammal eller redan förbrukad insomning — annars återanvänder
        // "Auto (HealthKit)" gårdagens/morgonens insovning och planen hamnar i det förflutna.
        let maxAge: TimeInterval = 2 * 3600   // max 2h gammal insomning
        guard let detected,
              Date().timeIntervalSince(detected) <= maxAge,
              detected > lastConsumedSleepStart else {
            self.lastDetectedSleepStart = nil
            return nil  // låt anroparen falla tillbaka på Date()
        }
        lastConsumedSleepStart = detected
        self.lastDetectedSleepStart = detected
        return detected
    }

    // Senast förbrukade insovning — stoppar återanvändning av samma detektion.
    private var lastConsumedSleepStart: Date {
        get { defaults.object(forKey: "lastConsumedSleepStart") as? Date ?? .distantPast }
        set { defaults.set(newValue, forKey: "lastConsumedSleepStart") }
    }
    private let defaults = UserDefaults.standard
}
