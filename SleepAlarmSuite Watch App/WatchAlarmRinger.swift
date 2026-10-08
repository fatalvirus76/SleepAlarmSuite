import Foundation
import WatchKit
import AVFoundation
import Combine

// Riktigt väckningslarm på klockan.
//
// Vanliga notiser (UNUserNotificationCenter) ger EN kort pingsignal — nedfälld handled,
// tyst läge och Fokus äter upp den, och användaren sover vidare. Riktigt larm på watchOS
// kräver en schemalagd WKExtendedRuntimeSession av typen "alarm"
// (kräver WKBackgroundModes = ["alarm"] i watch-appens Info.plist):
//
//   • start(at:) schemalägger starttiden upp till 36 h framåt. Anropet MÅSTE ske medan
//     appen är aktiv — annars sparas tiden och försöket görs om nästa gång appen blir aktiv.
//   • När tiden är inne startar systemet sessionen även om appen inte körs (appen startas
//     i bakgrunden och WKApplicationDelegate.handle(_:) anropas).
//   • notifyUser(hapticType:repeatHandler:) spelar en REPETERANDE haptik. Är appen inte
//     aktiv visas dessutom systemets larm-alert (fullskärm med Stopp-knapp) — haptiken
//     fortsätter tills användaren stoppar.
//   • Vi loopar samtidigt en egen ljudsignal så klockans högtalare hörs (extended runtime
//     sessions får spela ljud/haptik även efter att skärmen slocknat).
@MainActor
final class WatchAlarmRinger: NSObject, ObservableObject {
    static let shared = WatchAlarmRinger()

    @Published private(set) var isRinging = false
    @Published private(set) var lastError: String?
    @Published private(set) var statusText: String = "Inget larm schemalagt"

    private var session: WKExtendedRuntimeSession?
    private var scheduledFireDate: Date?
    /// Sluttiden för planen vi vill larma på. nil = användaren har stoppat.
    private var wantedFireDate: Date?
    /// false = användaren har stoppat; en session som ändå startar ska inte ringa.
    private var ringEnabled = false
    private var audio: AVAudioPlayer?
    private var testStopTask: Task<Void, Never>?

    /// watchOS tillåter som mest 36 h framåt.
    private static let maxScheduleAhead: TimeInterval = 35 * 3600

    /// Sant när ett klocklarm är schemalagt eller ringer just nu.
    var hasScheduledAlarm: Bool {
        if isRinging { return true }
        if session != nil, let scheduled = scheduledFireDate, scheduled > Date() { return true }
        if let wanted = wantedFireDate, wanted > Date() { return true }
        return false
    }

    // MARK: - Schemaläggning

    /// Schemalägger (eller flyttar) larmet till `fireDate`.
    func schedule(fireDate: Date) {
        wantedFireDate = fireDate
        ringEnabled = true
        guard fireDate > Date() else {
            lastError = "Tiden har redan passerat — inget klocklarm schemalagt."
            statusText = "Inget larm schemalagt"
            return
        }
        // watchOS: start(at:) får bara anropas i aktivt läge. Annars väntar vi.
        guard WKApplication.shared().applicationState == .active else {
            statusText = "Schemaläggs när appen är aktiv"
            return
        }
        guard fireDate.timeIntervalSinceNow <= Self.maxScheduleAhead else {
            statusText = "Schemaläggs när det är mindre än 36 h kvar"
            return
        }
        invalidateSession()

        let s = WKExtendedRuntimeSession()
        s.delegate = self
        session = s
        scheduledFireDate = fireDate
        s.start(at: fireDate)
        statusText = "Klocklarm \(fireDate.formattedTimeSV())"
        lastError = nil
    }

    /// Anropas varje gång appen blir aktiv: watchOS kräver aktiv app för start(at:),
    /// så ett larm som kom in medan appen låg i bakgrunden schemaläggs här.
    func schedulePendingIfPossible() {
        guard let wanted = wantedFireDate, wanted > Date() else { return }
        if session?.state == .running { return }
        if let scheduled = scheduledFireDate,
           abs(scheduled.timeIntervalSince(wanted)) < 1,
           session != nil {
            return
        }
        schedule(fireDate: wanted)
    }

    /// Stoppar larmet helt (Stoppa-knappen eller stopp skickat från iPhone).
    func cancel() {
        wantedFireDate = nil
        ringEnabled = false
        testStopTask?.cancel()
        testStopTask = nil
        stopRinging()
        invalidateSession()
        scheduledFireDate = nil
        statusText = "Inget larm schemalagt"
    }

    /// Testar hela larmkedjan direkt (samma session + haptik + ljud som det riktiga larmet).
    func ringNow(seconds: Double = 8, restoreFireDate: Date? = nil) {
        cancel()
        guard WKApplication.shared().applicationState == .active else {
            lastError = "Öppna appen för att testa larmet."
            return
        }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        session = s
        wantedFireDate = restoreFireDate
        ringEnabled = true
        // Måste vara en schemalagd (start(at:)) session — notifyUser ignoreras annars.
        s.start(at: Date().addingTimeInterval(2))
        statusText = "Testar larmet …"
        testStopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds + 3))
            guard let self, !Task.isCancelled else { return }
            self.stopRinging()
            self.invalidateSession()
            self.testStopTask = nil
            self.scheduledFireDate = nil
            if let restore = restoreFireDate, restore > Date() {
                self.schedule(fireDate: restore)
            } else {
                self.wantedFireDate = nil
                self.ringEnabled = false
                self.statusText = "Testet klart"
            }
        }
    }

    private func invalidateSession() {
        if let s = session, s.state != .invalid {
            // Schemalagda (start(at:)) sessioner går bara att avbryta från aktiv app —
            // annars städas de upp nästa gång appen blir aktiv.
            s.invalidate()
        }
        session = nil
    }

    // MARK: - Ringandet

    private func startRinging() {
        guard ringEnabled else {
            // Användaren har stoppat larmet medan sessionen var schemalagd.
            invalidateSession()
            scheduledFireDate = nil
            return
        }
        // En session som startar på en tid vi inte längre vill larma på är gammal.
        if let wanted = wantedFireDate, let scheduled = scheduledFireDate,
           abs(wanted.timeIntervalSince(scheduled)) > 1 {
            invalidateSession()
            scheduledFireDate = nil
            return
        }
        isRinging = true
        statusText = "LARM RINGER"
        startBeeping()
        // Repeterande haptik; systemets larm-alert visas när appen inte är aktiv.
        session?.notifyUser(hapticType: .notification, repeatHandler: { outHapticType in
            outHapticType.pointee = .retry
            return 10          // sekunder mellan signalerna (max 60)
        })
        WKInterfaceDevice.current().play(.notification)
    }

    private func stopRinging() {
        isRinging = false
        audio?.stop()
        audio = nil
    }

    private func startBeeping() {
        guard audio == nil else { return }
        do {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(data: Self.beepWAV())
            player.numberOfLoops = -1        // loopar tills vi stoppar
            player.volume = 0.9
            player.play()
            audio = player
        } catch {
            lastError = "Ljudet kunde inte startas: \(error.localizedDescription)"
        }
    }

    /// Genererar en tvåtons väckningssignal som WAV i minnet — ingen ljudfil behövs i bundlen.
    private static func beepWAV() -> Data {
        let sampleRate = 44_100.0
        let freqHigh = 1_046.5          // C6
        let freqLow = 783.99            // G5
        var samples: [Int16] = []

        func appendTone(_ freq: Double, seconds: Double) {
            let count = Int(sampleRate * seconds)
            let fade = Int(sampleRate * 0.015)
            for i in 0..<count {
                let t = Double(i) / sampleRate
                let attack = fade > 0 ? min(1.0, Double(i) / Double(fade)) : 1.0
                let release = fade > 0 ? min(1.0, Double(count - i) / Double(fade)) : 1.0
                let envelope = max(0.0, min(attack, release))
                let value = sin(2.0 * Double.pi * freq * t) * 0.85 * envelope
                samples.append(Int16(max(-1.0, min(1.0, value)) * 32_767))
            }
        }

        func appendSilence(seconds: Double) {
            samples.append(contentsOf: [Int16](repeating: 0, count: Int(sampleRate * seconds)))
        }

        appendTone(freqHigh, seconds: 0.22)
        appendSilence(seconds: 0.06)
        appendTone(freqHigh, seconds: 0.22)
        appendSilence(seconds: 0.06)
        appendTone(freqLow, seconds: 0.30)
        appendSilence(seconds: 0.55)

        // WAV-header (PCM 16-bit mono)
        let dataBytes = samples.count * 2
        var wav = Data()
        func append(_ s: String) { wav.append(contentsOf: Array(s.utf8)) }
        func append32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { wav.append(contentsOf: $0) } }
        func append16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { wav.append(contentsOf: $0) } }
        append("RIFF")
        append32(UInt32(36 + dataBytes))
        append("WAVEfmt ")
        append32(16)
        append16(1)                                  // PCM
        append16(1)                                  // mono
        append32(UInt32(sampleRate))
        append32(UInt32(sampleRate) * 2)             // byte rate
        append16(2)                                  // block align
        append16(16)                                 // bits per sample
        append("data")
        append32(UInt32(dataBytes))
        samples.withUnsafeBufferPointer { wav.append(Data(buffer: $0)) }
        return wav
    }
}

// MARK: - WKExtendedRuntimeSessionDelegate

extension WatchAlarmRinger: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        startRinging()
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        stopRinging()
    }

    func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        stopRinging()
        session = nil
        scheduledFireDate = nil
        if let error {
            lastError = "Klocklarmet: \(error.localizedDescription)"
        } else if reason == .expired {
            statusText = "Larmet avslutades efter 30 min"
        }
    }
}

// MARK: - Appdelegat
//
// När systemet startar om appen i bakgrunden för ett schemalagt larm anropas handle(_:)
// här. Sätter vi ingen delegat på sessionen avslutar systemet den — och då ringer inget.
final class WatchExtensionDelegate: NSObject, WKApplicationDelegate {
    func handle(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        WatchAlarmRinger.shared.adopt(extendedRuntimeSession)
    }
}

extension WatchAlarmRinger {
    /// Tar över en session som systemet skapade åt oss vid bakgrundsstart.
    func adopt(_ incoming: WKExtendedRuntimeSession) {
        invalidateSession()
        incoming.delegate = self
        session = incoming
        scheduledFireDate = wantedFireDate
        // Om appen inte är aktiv visas systemets larm-alert när vi spelar haptiken.
        startRinging()
    }
}
