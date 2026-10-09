// Does Apple's on-device model know which requests belong in System Settings, and which pane?
// Experiment. Usage: swiftc -O settings_route.swift -o r && ./r goals.json out.json
import Foundation
import FoundationModels

@Generable
struct Where {
    @Guide(description: "true only if the request is about changing the Mac's own settings (Wi-Fi, sound output, Bluetooth, camera or microphone permission for an app, screen brightness, text size for the whole screen, printers, notifications, software updates, storage, wallpaper, passwords). false if it is about a document, photo, file, email, website or message.")
    var isSettings: Bool
    @Guide(description: "If isSettings, the System Settings sidebar pane to open first, exactly as named in the list. Otherwise an empty string.")
    var pane: String
}

let panes = ["Wi‑Fi", "Bluetooth", "Network", "Battery", "General", "Accessibility", "Appearance", "Control Center", "Siri",
             "Privacy & Security", "Desktop & Dock", "Displays", "Wallpaper", "Notifications", "Sound", "Focus", "Screen Time",
             "Lock Screen", "Touch ID & Password", "Users & Groups", "Internet Accounts", "Printers & Scanners", "Keyboard", "Mouse", "Trackpad"]
let goals = try JSONDecoder().decode([String].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
var out: [[String: String]] = []
let t0 = Date()
for g in goals {
    let s = LanguageModelSession(instructions: "You know macOS System Settings well. Panes: \(panes.joined(separator: ", ")). Decide where an older person's request should be handled.")
    let r = try? await s.respond(to: "Request: \(g)", generating: Where.self)
    out.append(["goal": g, "settings": r.map { "\($0.content.isSettings)" } ?? "?", "pane": r?.content.pane ?? ""])
}
try JSONEncoder().encode(out).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
print("\(goals.count) goals in \(Int(Date().timeIntervalSince(t0)))s")
