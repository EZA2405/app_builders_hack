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

    /// The plan sentence misreads Taglish ("Hindi" taken as the language), so it's only written for English.
    static func isEnglish(_ s: String) -> Bool {
        let taglishWords = ["daw", "ako", "ko", "yung", "ng", "sa", "paano", "naman", "po", "mo", "ang", "kasi", "hindi"]
        let words = Set(s.lowercased().components(separatedBy: CharacterSet.letters.inverted))
        return words.intersection(taglishWords).count < 2   // NaturalLanguage has no Tagalog model
    }

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
    static func pane(for goal: String, app: String = "Finder") async -> String? {
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
        // Request text only (measured: telling it the app in front made it miss real settings jobs). Documents are
        // protected by the caller: a confident in-app pick wins before this is asked.
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

/// The memory for a whole journey: Apple's on-device model writes, once, the names the person will click in
/// order ("System Settings", "Privacy & Security", "Camera", "zoom.us"). Each step, the next name is used only if
/// it is on screen exactly; otherwise Laya picks. The model sees only the request text, never the screen.
@Generable
struct Waypoints {
    @Guide(description: "2 to 5 names the person clicks, in order, exactly as macOS shows them (Dock apps, sidebar items, list rows, buttons, switches). No menu bar menus. Start with the app to open if it isn't the app in front.")
    var names: [String]
}

enum Orchestrator {
    static func plan(goal: String, app: String) async -> [String] {
        guard PlanVoice.available else { return [] }
        let s = LanguageModelSession(instructions: """
        You know macOS 26 well and help older people. Requests may be in English, Tagalog or Taglish. \\
        Write the route as the on-screen names they click. Examples: \\
        "they can't see me on Zoom" -> System Settings, Privacy & Security, Camera, zoom.us. \\
        "connect my headphones" -> System Settings, Bluetooth. \\
        "update my mac" -> System Settings, General, Software Update. \\
        "make the text on the screen bigger" -> System Settings, Accessibility, Display, Text size. \\
        "turn on wifi" -> System Settings, Wi‑Fi.
        """)
        let task = Task { try? await s.respond(to: "App in front: \(app)\nRequest: \(goal)", generating: Waypoints.self,
                                                 options: GenerationOptions(sampling: .greedy)).content.names }
        let timeout = Task { try? await Task.sleep(nanoseconds: 3_500_000_000); task.cancel() }
        let r = await task.value ?? []
        timeout.cancel()
        return Array(r.prefix(5))
    }

    static func same(_ a: String, _ b: String) -> Bool {
        func n(_ s: String) -> String { s.lowercased().replacingOccurrences(of: "‑", with: "-").replacingOccurrences(of: "…", with: "")
            .trimmingCharacters(in: .whitespaces) }
        return n(a) == n(b)
    }
}


/// "Something isn't working" requests are troubleshooting, not navigation: Apple's on-device model lists the
/// likely fixes once, most likely first, and Gabay walks them one at a time, asking "Is it working now?".
@Generable
struct Fix {
    @Guide(description: "One short, calm sentence saying what we'll check, e.g. \"Let's check that your video call app may use the camera.\"")
    var say: String
    @Guide(description: "The task as a short instruction for a Mac guide, e.g. \"allow the video call app to use the camera\"")
    var task: String
}

@Generable
struct Troubleshoot {
    @Guide(description: "true if the person says something is not working or is wrong (no sound, can't see me, no internet, printer won't print); false if they just want to do something")
    var isProblem: Bool
    @Guide(description: "If isProblem: 2 or 3 fixes a person can do on a Mac, most likely first. Otherwise empty.")
    var fixes: [Fix]
}

enum Troubleshooter {
    static func fixes(for goal: String) async -> [Fix] {
        guard PlanVoice.available else { return [] }
        let s = LanguageModelSession(instructions: """
        You help older people fix everyday problems on a Mac. Requests may be in English, Tagalog or Taglish \
        ("hindi" means "not", "daw" means "they say"). Only a request that says something is broken or not working \
        is a problem; a request to do or change something is not. Each fix must be about the exact thing that's \
        broken (sound problems get sound fixes, camera problems get camera fixes), using macOS 26 names \
        (System Settings, not System Preferences).
        """)
        let task = Task { try? await s.respond(to: "Request: \(goal)", generating: Troubleshoot.self,
                                                 options: GenerationOptions(sampling: .greedy)).content }
        let timeout = Task { try? await Task.sleep(nanoseconds: 4_000_000_000); task.cancel() }
        let r = await task.value
        timeout.cancel()
        guard let r, r.isProblem else { return [] }
        return Array(r.fixes.prefix(3))
    }
}

/// Websites: is the request for the page that's open, and if not, which site? Apple's on-device model sees only
/// the request and the page's title and address (no page content).
@Generable
struct SiteCheck {
    @Guide(description: "true if the request can be done on the page that is open now")
    var onThisPage: Bool
    @Guide(description: "If not, the website's everyday name, e.g. YouTube, Gmail, Shopee, PhilHealth. Otherwise empty.")
    var siteName: String
    @Guide(description: "If not, the website address to type, e.g. youtube.com. Otherwise empty.")
    var address: String
}

enum SiteRoute {
    static func check(goal: String, title: String, url: String) async -> SiteCheck? {
        guard PlanVoice.available else { return nil }
        let host = URL(string: url)?.host ?? url
        let s = LanguageModelSession(instructions: "You help older people use websites. Requests may be in English, Tagalog or Taglish.")
        let task = Task { try? await s.respond(to: "Page open now: \"\(title)\" at \(host)\nRequest: \(goal)", generating: SiteCheck.self,
                                                 options: GenerationOptions(sampling: .greedy)).content }
        let timeout = Task { try? await Task.sleep(nanoseconds: 3_000_000_000); task.cancel() }
        let r = await task.value
        timeout.cancel()
        return r
    }
}

/// Websites: a request often bundles several things ("find an adobo video and turn on the subtitles"). Apple's
/// on-device model splits it once into ordered parts; the page picker works on one part at a time.
@Generable
struct WebParts {
    @Guide(description: "1 to 4 short parts in order, each one thing to do on the website, in plain English, e.g. \"search for how to cook adobo\", \"open a video\", \"turn on captions\". Keep names and search words from the request.")
    var parts: [String]
}

enum WebPlan {
    static func parts(for goal: String, site: String) async -> [String] {
        guard PlanVoice.available else { return [] }
        let s = LanguageModelSession(instructions: "You help older people use websites. Requests may be in English, Tagalog or Taglish; write the parts in English.")
        let task = Task { try? await s.respond(to: "Website: \(site)\nRequest: \(goal)", generating: WebParts.self,
                                                 options: GenerationOptions(sampling: .greedy)).content.parts }
        let timeout = Task { try? await Task.sleep(nanoseconds: 3_000_000_000); task.cancel() }
        let r = await task.value ?? []
        timeout.cancel()
        return Array(r.prefix(4))
    }
}
