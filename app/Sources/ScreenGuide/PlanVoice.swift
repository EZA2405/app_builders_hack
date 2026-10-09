import Foundation
import FoundationModels

/// Apple's on-device model words the plan for a route Laya already chose ("I'll save a smaller copy of
/// your photo."). It never chooses what to click — measured: rewriting goals for the picker hurt accuracy
/// (ml/RESULTS.md) — it only explains, so a surprising-but-valid route doesn't feel like a mistake.
@Generable
struct PlanLine {
    @Guide(description: "One warm, plain sentence (max 14 words) telling an older person what you will help them do, naming the result they get. No app jargon, no menu names.")
    var sentence: String
}

enum PlanVoice {
    static var available: Bool { SystemLanguageModel.default.availability == .available }

    static func prewarm() {
        guard available else { return }
        LanguageModelSession().prewarm()
    }

    /// e.g. goal "make this photo smaller so I can email it", route "File > Export…" -> "I'll help you save a smaller copy of your photo to email."
    static func plan(goal: String, route: String) async -> String? {
        guard available else { return nil }
        let session = LanguageModelSession(instructions: """
        You are a patient helper for older people using a Mac. Another part of the app already decided which \
        menu command or button to use. In one short sentence starting with "I'll help you", say what this will \
        do for the person, in everyday words. Do not mention menus, commands or clicking.
        """)
        let task = Task { try? await session.respond(to: "Their request: \(goal)\nThe app will use: \(route)", generating: PlanLine.self) }
        // Never hold the guide up for more than ~2.5 s; the step works without the sentence.
        let timeout = Task { try? await Task.sleep(nanoseconds: 2_500_000_000); task.cancel() }
        let r = await task.value
        timeout.cancel()
        return r?.content.sentence
    }
}

/// Apple's on-device model on the request text alone (no screen data): is this a System Settings job, and
/// which pane? Measured on real requests it separates settings tasks far better than the small picker, which
/// confidently matched look-alike words ("update my computer" → Finder's Go > Computer).
@Generable
struct SettingsGuess {
    @Guide(description: "true only if the request is about changing the Mac's own settings (Wi-Fi, sound output, Bluetooth, camera or microphone permission for an app, screen brightness, text size for the whole screen, printers, notifications, software updates, storage, wallpaper, passwords). false if it is about a document, photo, file, email, website, music or message.")
    var isSettings: Bool
    @Guide(description: "If isSettings, the System Settings sidebar pane to open first, exactly as named in the list. Otherwise an empty string.")
    var pane: String
}

enum SettingsRoute {
    static let panes = ["Wi‑Fi", "Bluetooth", "Network", "Battery", "General", "Accessibility", "Appearance", "Control Center",
                        "Siri", "Privacy & Security", "Desktop & Dock", "Displays", "Wallpaper", "Notifications", "Sound", "Focus",
                        "Screen Time", "Lock Screen", "Touch ID & Password", "Users & Groups", "Internet Accounts",
                        "Printers & Scanners", "Keyboard", "Mouse", "Trackpad"]

    /// The pane name if this is a settings job, else nil. Never waits more than ~3 s.
    static func pane(for goal: String) async -> String? {
        guard PlanVoice.available else { return nil }
        let s = LanguageModelSession(instructions: """
        You know macOS System Settings well. Decide where an older person's request should be handled. \
        Requests may be in English, Tagalog or Taglish. What the panes are for: \
        Privacy & Security: which apps may use the camera, microphone or screen (people on a video call can't see or hear them). \
        Displays: screen brightness, resolution, larger text on the whole screen. Accessibility: text size, zoom, reading aloud. \
        Sound: volume, speakers, which microphone. Bluetooth: headphones, speakers, mouse. Wi‑Fi: internet connection. \
        General: Software Update, Storage (free space), About. Printers & Scanners: add a printer. Notifications: pop-up alerts. \
        Wallpaper: desktop picture. Users & Groups / Touch ID & Password: login password. \
        All panes: \(panes.joined(separator: ", ")).
        """)
        // Greedy: the same request must take the same route every time.
        let task = Task { try? await s.respond(to: "Request: \(goal)", generating: SettingsGuess.self,
                                               options: GenerationOptions(sampling: .greedy)).content }
        let timeout = Task { try? await Task.sleep(nanoseconds: 3_000_000_000); task.cancel() }
        let r = await task.value
        timeout.cancel()
        guard let r, r.isSettings else { return nil }
        return normalize(r.pane) ?? "General"
    }

    /// "Display" → "Displays", "Wi-Fi" → "Wi‑Fi", "Storage" → "General" (Storage lives under General).
    static func normalize(_ p: String) -> String? {
        let k = p.lowercased().replacingOccurrences(of: "‑", with: "-")
        if k.contains("storage") || k.contains("software update") { return "General" }
        if k.contains("camera") || k.contains("microphone") || k.contains("privacy") { return "Privacy & Security" }
        return panes.first { let n = $0.lowercased().replacingOccurrences(of: "‑", with: "-"); return n == k || n.hasPrefix(k) || k.hasPrefix(n) }
    }
}
