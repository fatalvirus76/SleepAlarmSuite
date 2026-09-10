import Foundation

/// Gemensam konfig för Watch App (+ ev. widget/extension).
///
/// **Viktigt:** Det får bara finnas *en* fil med namnet `AppConfig.swift` i samma target,
/// annars kan Swift generera dubbla `*.stringsdata`-outputs ("Multiple commands produce … AppConfig.stringsdata").
enum AppConfig {
    /// Om du sätter upp App Group för att dela data mellan app + widget:
    /// 1) Capabilities → App Groups i (minst) Watch App-target
    /// 2) Sätt samma grupp-id här i alla targets som delar data
    static let appGroupID: String? = nil // t.ex. "group.com.example.sleepalarm"

    static var defaults: UserDefaults {
        if let id = appGroupID, let ud = UserDefaults(suiteName: id) {
            return ud
        }
        return .standard
    }

    /// Identifier-prefix för notiser så vi kan rensa bara våra.
    static let notificationPrefix = "sleepalarm.watch."
}
