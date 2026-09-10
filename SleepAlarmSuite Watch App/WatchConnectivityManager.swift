import Foundation
import WatchConnectivity
import Combine

/// Tvåvägssynk med iPhone-appen via WatchConnectivity.
/// - applicationContext: "senaste tillståndet" som alltid levereras när mottagaren startar.
/// - sendMessage: omedelbara kommandon när motparten är nåbar (med fall-back till applicationContext).
/// Inbyggd princip: den sida som senast ändrade planen (start/snooze/stopp) har `origin`-fältet;
/// motparten schemalägger ALDRIG om en plan den själv redan schemalagt (ser sin egen origin).
final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isSupported: Bool = WCSession.isSupported()
    @Published var isReachable: Bool = false
    @Published var lastMessage: String?

    /// Callback som sätts av appen: anropas när iPhone skickar en plan/åtgärd hit.
    var onRemotePlan: ((AlarmPlan) -> Void)?
    var onRemoteAction: ((String) -> Void)?
    /// Sätts av appen: returnerar aktuell plan när motparten frågar.
    var planProvider: (() -> AlarmPlan?)?

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Nycklar
    static let keyPlanData = "planData"
    static let keyOrigin = "origin"
    static let keyAction = "action"

    // MARK: - Skicka plan (start/snooze) till iPhone
    func sendPlan(_ plan: AlarmPlan) {
        guard let session, session.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(plan) else { return }
        let ctx: [String: Any] = [
            Self.keyPlanData: data,
            Self.keyOrigin: "watch"
        ]
        // applicationContext levereras även om iPhone-appen inte körs just nu.
        try? session.updateApplicationContext(ctx)

        // Om telefonen är nåbar just nu, skicka också direkt för omedelbar synk.
        if session.isReachable {
            session.sendMessage(ctx, replyHandler: nil) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.lastMessage = "Kunde inte nå iPhone direkt — planen synkas när appen öppnas."
                }
            }
        }
    }

    // MARK: - Skicka åtgärd (stopp) till iPhone
    func sendAction(_ action: String) {
        guard let session, session.activationState == .activated else { return }
        let ctx: [String: Any] = [
            Self.keyAction: action,
            Self.keyOrigin: "watch"
        ]
        try? session.updateApplicationContext(ctx)
        if session.isReachable {
            session.sendMessage(ctx, replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: - Hämta senaste planen från iPhone (manuell förfrågan)
    func requestPlanFromPhone() {
        guard let session, session.activationState == .activated else { return }
        guard session.isReachable else {
            DispatchQueue.main.async { self.lastMessage = "iPhone ej nåbar" }
            return
        }
        session.sendMessage(["request": "plan"], replyHandler: { reply in
            DispatchQueue.main.async {
                if let data = reply[Self.keyPlanData] as? Data,
                   let plan = try? JSONDecoder().decode(AlarmPlan.self, from: data) {
                    self.onRemotePlan?(plan)
                    self.lastMessage = "Hämtade plan från iPhone."
                } else {
                    self.lastMessage = "Ingen plan på iPhone."
                }
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async { self?.lastMessage = "WC error: \(error.localizedDescription)" }
        })
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            if let error { self.lastMessage = "WC activation error: \(error.localizedDescription)" }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    // applicationContext: levereras automatiskt när appen startar (och vid varje uppdatering).
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.handleIncoming(applicationContext) }
    }

    // Direktmeddelanden när motparten är nåbar.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.handleIncoming(message)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
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

    // MARK: - Gemensam hantering av inkommande nyttolast
    private func handleIncoming(_ message: [String: Any]) {
        let origin = message[Self.keyOrigin] as? String ?? "unknown"
        // Ignorera eko av våra egna uppdateringar.
        guard origin == "phone" else { return }

        if let data = message[Self.keyPlanData] as? Data,
           let plan = try? JSONDecoder().decode(AlarmPlan.self, from: data) {
            onRemotePlan?(plan)
            lastMessage = "Plan mottagen från iPhone."
        } else if let action = message[Self.keyAction] as? String {
            onRemoteAction?(action)
            lastMessage = "Åtgärd från iPhone: \(action)"
        }
    }
}
