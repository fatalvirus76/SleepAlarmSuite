//
//  I18n.swift
//  Sleep Alarm Suite
//
//  Enkelt i18n-system: UI-strängar slås upp med L(...).
//  Nycklarna är de svenska originalsträngarna; engelska finns i I18nTables.
//  Språkvalet sparas i UserDefaults ("appLanguage": "sv" | "en").
//  (Samma mönster som i LLM-Chat, men svenska är default här eftersom
//  appen alltid varit svensk.)
//

import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case swedish = "sv"
    case english = "en"
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .swedish: return "Svenska"
        case .english: return "English"
        }
    }
}

final class I18nManager: ObservableObject {
    static let shared = I18nManager()

    /// Aktivt språk. UI prenumererar via @ObservedObject; L() läser UserDefaults
    /// direkt så att uppslagning fungerar från vilken tråd som helst.
    @Published var language: AppLanguage

    /// Snabbkoll för formatterare m.m.
    static var isSwedish: Bool {
        UserDefaults.standard.string(forKey: "appLanguage") != "en"
    }

    private init() {
        // Svenska är default (appens ursprungsspråk); sparat språk vinner.
        let stored = UserDefaults.standard.string(forKey: "appLanguage") ?? "sv"
        language = AppLanguage(rawValue: stored) ?? .swedish
    }

    /// Trådsäker uppslagning: läser UserDefaults direkt i stället för att
    /// korsa actor-gränser.
    nonisolated func str(_ key: String) -> String {
        let stored = UserDefaults.standard.string(forKey: "appLanguage") ?? "sv"
        guard stored == "en" else { return key }
        return I18nTables.svToEn[key] ?? key
    }

    func setLanguage(_ l: AppLanguage) {
        language = l
        UserDefaults.standard.set(l.rawValue, forKey: "appLanguage")
    }
}

/// Slå upp en svensk UI-sträng mot aktivt språk (svenska default).
/// Strängar med %@ fylls i med argumenten i ordning.
func L(_ key: String, _ args: Any...) -> String {
    var s = I18nManager.shared.str(key)
    if !args.isEmpty {
        let fmtArgs: [CVarArg] = args.map { $0 as? CVarArg ?? String(describing: $0) }
        s = String(format: s, arguments: fmtArgs)
    }
    return s
}
