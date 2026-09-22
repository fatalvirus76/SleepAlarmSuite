import Foundation
import WatchConnectivity
import Combine

// iPhone-sidans WatchConnectivity-motpart till Watch App:ens WatchConnectivityManager.
// Samma nycklar, samma princip: applicationContext för "senaste tillstånd",
// sendMessage för omedelbar synk, origin-fält stoppar eko-beroende dubbelhantering.
final class PhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isPaired: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    @Published var isReachable: Bool = false
    @Published var lastMessage: String?

    var onRemotePlan: ((AlarmPlan) -> Void)?
    var onRemoteAction: ((String) -> Void)?
    var planProvider: (() -> AlarmPlan?)?

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    static let keyPlanData = "planData"
    static let keyOrigin = "origin"
    static let keyAction = "action"

    // MARK: - Skicka plan till klockan
    func sendPlan(_ plan: AlarmPlan) {
        guard let session, session.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(plan) else { return }
        let ctx: [String: Any] = [
            Self.keyPlanData: data,
            Self.keyOrigin: "phone"
        ]
        try? session.updateApplicationContext(ctx)
        if session.isReachable {
            session.sendMessage(ctx, replyHandler: nil) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.lastMessage = "Kunde inte nå klockan direkt — planen synkas när appen öppnas."
                }
            }
        }
    }

    func sendAction(_ action: String) {
        guard let session, session.activationState == .activated else { return }
        let ctx: [String: Any] = [
            Self.keyAction: action,
            Self.keyOrigin: "phone"
        ]
        try? session.updateApplicationContext(ctx)
        if session.isReachable {
            session.sendMessage(ctx, replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: - Status
    // Uppdaterar par/installerad/nåbar-status. Måste köras vid fler tillfällen än
    // bara aktivering — activation-callbacken kan komma innan pairing-info hunnit
    // stabiliseras, och vid varm appstart kommer den kanske inte alls.
    func refreshStatus() {
        guard let session else { return }
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable
        }
    }

    func requestPlanFromWatch() {
        guard let session, session.activationState == .activated else { return }
        guard session.isReachable else {
            DispatchQueue.main.async { self.lastMessage = "Klockan ej nåbar" }
            return
        }
        session.sendMessage(["request": "plan"], replyHandler: { reply in
            DispatchQueue.main.async {
                if let data = reply[Self.keyPlanData] as? Data,
                   let plan = try? JSONDecoder().decode(AlarmPlan.self, from: data) {
                    self.onRemotePlan?(plan)
                    self.lastMessage = "Hämtade plan från klockan."
                } else {
                    self.lastMessage = "Ingen plan på klockan."
                }
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async { self?.lastMessage = "WC error: \(error.localizedDescription)" }
        })
    }

    // MARK: - WCSessionDelegate (iOS-sidan)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.refreshStatus()
            if let error { self.lastMessage = "WC activation error: \(error.localizedDescription)" }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Klockan bytte handled/parades om — aktivera igen mot ny klocka.
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.refreshStatus()
            self.handleIncoming(applicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.refreshStatus()
            self.handleIncoming(message)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.refreshStatus()
            if message["request"] as? String == "plan" {
                if let plan = self.planProvider?(),
                   let data = try? JSONEncoder().encode(plan) {
                    replyHandler([Self.keyPlanData: data])
                } else {
                    replyHandler([:])
                }
            }
            self.handleIncoming(message)
        }
    }

    private func handleIncoming(_ message: [String: Any]) {
        let origin = message[Self.keyOrigin] as? String ?? "unknown"
        guard origin == "watch" else { return }

        if let data = message[Self.keyPlanData] as? Data,
           let plan = try? JSONDecoder().decode(AlarmPlan.self, from: data) {
            onRemotePlan?(plan)
            lastMessage = "Plan mottagen från klockan."
        } else if let action = message[Self.keyAction] as? String {
            onRemoteAction?(action)
            lastMessage = "Åtgärd från klockan: \(action)"
        }
    }
}
