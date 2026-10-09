//
//  I18nTables.swift
//  Sleep Alarm Suite
//
//  Ordbok: svensk UI-sträng -> engelska. Svenska är default (nyckeln).
//

nonisolated enum I18nTables {
    static let svToEn: [String: String] = [
        // MARK: Flikar / rubriker
        "Larm": "Alarm",
        "Statistik": "Statistics",
        "Tema": "Theme",
        "Planera": "Plan",
        "Plan": "Plan",
        "Mer": "More",
        "Stats": "Stats",
        "Översikt": "Overview",
        "Historik": "History",
        "Rensa": "Clear",
        "Etikett": "Label",
        "Start": "Start",
        "START": "START",
        "SÖMNLÄNGD": "SLEEP LENGTH",
        "Sömnlängd": "Sleep length",
        "SNOOZE": "SNOOZE",
        "Snooze": "Snooze",
        "Snooze (min)": "Snooze (min)",
        "Accent": "Accent",
        "Om": "About",

        // MARK: Hero / status
        "INGET AKTIVT LARM": "NO ACTIVE ALARM",
        "NÄSTA VÄCKNING": "NEXT WAKE-UP",
        "Notiser på": "Notifications on",
        "Notiser av": "Notifications off",
        "mål": "goal",
        "Klocka nära": "Watch near",
        "Klocka parad": "Watch paired",
        "Ingen klocka": "No watch",
        "Ingen plan ännu — tryck Starta nedan": "No plan yet — tap Start below",
        "Väckning passerad": "Wake-up passed",
        "%@ kvar": "%@ left",
        "Smart fönster %d min • steg %d min": "Smart window %d min • step %d min",

        // MARK: Knappar
        "Aktivera notiser": "Enable notifications",
        "Starta sömn-larm": "Start sleep alarm",
        "Stoppa": "Stop",
        "Hämta plan från klockan": "Fetch plan from watch",
        "Hämta plan från iPhone": "Fetch plan from iPhone",
        "Testa larm": "Test alarm",

        // MARK: Startlägen
        "Nu": "Now",
        "Manuellt": "Manual",
        "Auto (Health)": "Auto (Health)",
        "Auto (HealthKit)": "Auto (HealthKit)",
        "Auto": "Auto",
        "Klockan": "Clock",
        "Egen": "Custom",
        "Startar": "Starts",
        "Starttid": "Start time",
        "Ingen detektion än": "No detection yet",
        "Senaste insomning": "Latest sleep onset",
        "Timmar": "Hours",
        "Timme": "Hour",
        "Minut": "Minute",

        // MARK: Smart fönster
        "Smart fönster": "Smart window",
        "Fönster": "Window",
        "Steg i fönstret": "Window step",
        "Steg mellan larm": "Step between alarms",
        "Av": "Off",
        "Larmet väcker dig någonstans i fönstret före måltiden — ju mindre steg, desto tätare koll.":
            "The alarm wakes you somewhere in the window before the target time — the smaller the step, the tighter the check.",
        "Väcker någonstans i fönstret före måltiden.":
            "Wakes you somewhere in the window before the target time.",

        // MARK: Watch-kort
        "Apple Watch": "Apple Watch",
        "Parad": "Paired",
        "Klockapp installerad": "Watch app installed",
        "Nåbar nu": "Reachable now",
        "i bakgrunden · %@": "in background · %@",

        // MARK: Planera (watch)
        "Sömn-larm": "Sleep alarm",
        "%@ sömn från %@": "%@ of sleep from %@",
        "nu": "now",
        "kl. %@": "at %@",
        "Start kl. %@": "Start at %@",
        "Startar direkt när du trycker Starta.": "Starts right away when you tap Start.",
        "Ingen insomning hittad än.": "No sleep onset found yet.",
        "Senaste insomning: %@": "Latest sleep onset: %@",
        "Söker…": "Searching…",
        "Hämta från HealthKit": "Fetch from HealthKit",
        "Ändra under Planera-fliken.": "Change under the Plan tab.",

        // MARK: Statistik
        "pass": "sessions",
        "Loggade": "Logged",
        "Snitt 7": "Avg 7",
        "Snitt allt": "Avg all",
        "Snitt senaste 7": "Avg last 7",
        "Snitt alla": "Avg all",
        "Planerad sömnlängd": "Planned sleep length",
        "Ingen historik än — starta ett larm först.": "No history yet — start an alarm first.",
        "Ingen historik än.": "No history yet.",
        "väckning": "wake-up",
        "Senaste passen": "Recent sessions",
        "Timmar per pass (planerad sömnlängd)": "Hours per session (planned sleep length)",

        // MARK: Klockans inställningar
        "Aktuellt tema": "Current theme",
        "Notiser": "Notifications",
        "På": "On",
        "Behövs för att väcka med haptik och notis.": "Needed to wake you with haptics and a notification.",
        "Begär tillstånd": "Request permission",
        "Kopplad": "Connected",
        "Ej kopplad": "Not connected",
        "Används för att hitta senaste insomningstid (Auto-läget).": "Used to find the latest sleep onset (Auto mode).",
        "Senast upptäckt: %@": "Last detected: %@",
        "Aktivera HealthKit": "Enable HealthKit",
        "Synk med iPhone": "Sync with iPhone",
        "Session aktiv": "Session active",
        "iPhone nåbar": "iPhone reachable",
        "Väcker dig i ett smart fönster efter din planerade sömn.": "Wakes you in a smart window after your planned sleep.",

        // MARK: Klockans pill/status
        "Inga notiser": "No notifications",
        "Synkad": "Synced",
        "Ej synkad": "Not synced",
        "Klocklarm": "Watch alarm",
        "Inget klocklarm": "No watch alarm",
        "Tillåt notiser": "Allow notifications",
        "LARM RINGER": "ALARM RINGING",

        // MARK: Notiser / fel (schedulers, managers)
        "Notiser nekades. Slå på i Inställningar.": "Notifications denied. Enable them in Settings.",
        "Kunde inte begära notiser: %@": "Could not request notifications: %@",
        "Kunde inte schemalägga: %@": "Could not schedule: %@",
        "Väckningsfönster %d/%d. Öppna appen för snooze/stop.": "Wake-up window %d/%d. Open the app for snooze/stop.",
        "Dags att vakna! Öppna appen för snooze/stop.": "Time to wake up! Open the app for snooze/stop.",
        "Planen är avstängd — inget AlarmKit-larm schemalagt.": "Plan is disabled — no AlarmKit alarm scheduled.",
        "Tiden %@ har passerat — inget AlarmKit-larm schemalagt.": "Time %@ has passed — no AlarmKit alarm scheduled.",
        "AlarmKit ej auktoriserat — vanliga notiser används som reserv.": "AlarmKit not authorized — regular notifications are used as fallback.",
        "HealthKit är inte tillgängligt på den här enheten.": "HealthKit is not available on this device.",
        "HealthKit permission misslyckades: %@": "HealthKit permission failed: %@",
        "Kunde inte nå klockan direkt — planen synkas när appen öppnas.": "Could not reach the watch directly — the plan syncs when the app opens.",
        "Kunde inte nå iPhone direkt — planen synkas när appen öppnas.": "Could not reach the iPhone directly — the plan syncs when the app opens.",
        "Klockan ej nåbar": "Watch not reachable",
        "iPhone ej nåbar": "iPhone not reachable",
        "Hämtade plan från klockan.": "Fetched plan from watch.",
        "Hämtade plan från iPhone.": "Fetched plan from iPhone.",
        "Ingen plan på klockan.": "No plan on the watch.",
        "Ingen plan på iPhone.": "No plan on the iPhone.",
        "Plan mottagen från klockan.": "Plan received from watch.",
        "Plan mottagen från iPhone.": "Plan received from iPhone.",
        "Åtgärd från iPhone: %@": "Action from iPhone: %@",
        "Åtgärd från klockan: %@": "Action from watch: %@",
        "Inget larm schemalagt": "No alarm scheduled",
        "Tiden har redan passerat — inget klocklarm schemalagt.": "Time has already passed — no watch alarm scheduled.",
        "Schemaläggs när appen är aktiv": "Scheduled when the app is active",
        "Schemaläggs när det är mindre än 36 h kvar": "Scheduled when less than 36 h remain",
        "Klocklarm %@": "Watch alarm %@",
        "Öppna appen för att testa larmet.": "Open the app to test the alarm.",
        "Testar larmet …": "Testing alarm …",
        "Testet klart": "Test finished",
        "Ljudet kunde inte startas: %@": "Could not start sound: %@",

        // MARK: Teman (titlar + taglines)
        "Midnatt": "Midnight",
        "Mörk nattblå": "Dark night blue",
        "Dracula": "Dracula",
        "Lila & rosa": "Purple & pink",
        "Synthwave": "Synthwave",
        "Neon 80-tal": "Neon 80s",
        "Glas": "Glass",
        "Ljust & fruset": "Light & frozen",
        "Nord": "Nord",
        "Sval skandinavisk": "Cool Scandinavian",
        "Gryning": "Dawn",
        "Varm soluppgång": "Warm sunrise",

        // MARK: Preset-titlar
        "6 timmar": "6 hours",
        "7.5 timmar": "7.5 hours",
        "8 timmar": "8 hours",
        "9 timmar": "9 hours",

        "INGET LARM": "NO ALARM",
        "VÄCKNING": "WAKE-UP",
        "Tryck Starta": "Tap Start",
        "passerad": "passed",
        "Så här ser larmkortet ut": "This is what the alarm card looks like",
        "Datum": "Date",
        "HealthKit": "HealthKit",
        "%d min": "%d min",
        // MARK: Språkväljare
        "Språk": "Language",
        "Språk: %@": "Language: %@",
        "Svenska": "Svenska",
        "English": "English",
        "Språket gäller hela appen och sparas direkt.": "The language applies to the whole app and is saved instantly.",
        "Temat gäller hela appen och sparas direkt.": "The theme applies to the whole app and is saved instantly."
    ]
}
