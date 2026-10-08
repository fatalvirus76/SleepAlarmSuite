import Foundation
import UserNotifications

// Gemensam konfig för iPhone-appen. Speglar Watch App:ens AppConfig (samma notis-prefix
// så att båda sidor kan rensa sina egna schemalagda notiser oberoende av varandra).
enum AppConfig {
    /// Identifier-prefix för iPhone-notiser (klockan använder sitt eget prefix).
    static let notificationPrefix = "sleepalarm.phone."
}
