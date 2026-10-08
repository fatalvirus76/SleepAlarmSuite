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
    /// Senaste gången klockappen hörde av sig (mottaget meddelande/applicationContext
    /// eller lyckad direktleverans). WCSession:s egna flaggor (isPaired/isWatchAppInstalled)
    /// uppdateras BARA när sessionen aktiveras om — installerar man klockappen medan
    /// telefonappen redan kör ligger de kvar på false trots att appen finns och synkar.
    /// Kontaktbeviset är därför den pålitliga källan.
    @Published private(set) var lastWatchContact: Date?

    private let contactKey = "watch_last_contact_v1"

    var onRemotePlan: ((AlarmPlan) -> Void)?
    var onRemoteAction: ((String) -> Void)?
    var planProvider: (() -> AlarmPlan?)?

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    override init() {
        super.init()
        lastWatchContact = UserDefaults.standard.object(forKey: contactKey) as? Date
        session?.delegate = self
        session?.activate()
    }

    /// Klockappen är installerad om WCSession säger det ELLER om klockan hörde av sig.
    var watchAppConfirmedInstalled: Bool {
        isWatchAppInstalled || lastWatchContact != nil
    }

    private func noteWatchContact() {
        let now = Date()
        lastWatchContact = now
        UserDefaults.standard.set(now, forKey: contactKey)
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
            // Brand-and-forget (watch-appens didReceiveMessage utan replyHandler svarar
            // inte på vanliga planer — en replyHandler skulle ge falsk timeout).
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
        // Är sessionen inte aktiv (t.ex. efter att klockappen installerats om, eller efter
        // handledsbyte) ligger isPaired/isWatchAppInstalled kvar på gamla värden. Aktivera om
        // så att flaggorna faktiskt uppdateras i stället för att ljuga i UI:t.
        if session.activationState != .activated {
            session.activate()
        }
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
                self.noteWatchContact()
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
            self.noteWatchContact()
            self.refreshStatus()
            self.handleIncoming(applicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.noteWatchContact()
            self.refreshStatus()
            self.handleIncoming(message)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.noteWatchContact()
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
