import Foundation
@preconcurrency import HealthKit
import Combine

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

    /// Försök hitta senaste “asleep” start.
    /// OBS: Sleep-samples skrivs ofta i efterhand. Detta är “best effort”.
    func detectRecentSleepStart(maxLookbackHours: Double = 12) async -> Date? {
        guard authorized, let type = sleepType else { return nil }

        let end = Date()
        let start = end.addingTimeInterval(-maxLookbackHours * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictEndDate)

        // Wrap HealthKit callback without capturing `self` inside the query closure.
        // This avoids Swift 6 strict concurrency errors about actor-isolated `self` in concurrently executing code.
        let (detected, errMsg): (Date?, String?) = await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 50, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    cont.resume(returning: (nil, "HealthKit query error: \(error.localizedDescription)"))
                    return
                }

                let cats = (samples as? [HKCategorySample]) ?? []

                // Hitta senaste sample som representerar “asleep”
                let asleepSample = cats.first(where: { sample in
                    if #available(watchOS 9.0, *) {
                        if let v = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                            // watchOS 9+: `.asleep` is deprecated; use `.asleepUnspecified`.
                            return v == .asleepUnspecified || v == .asleepCore || v == .asleepDeep || v == .asleepREM
                        }
                        return false
                    } else {
                        // Older fallback: historically `.asleep` == 1, `.inBed` == 0.
                        return sample.value == 1
                    }
                })

                cont.resume(returning: (asleepSample?.startDate, nil))
            }

            // Execute on our store (on MainActor, but safe to call here).
            HKHealthStore().execute(query)
        }

        self.lastDetectedSleepStart = detected
        self.lastError = errMsg
        return detected
    }
}
