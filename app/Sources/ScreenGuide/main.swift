import AppKit
import ApplicationServices

// Dev entry points (the guide UI comes later):
//   ScreenGuide.app --dump <AppName> <out.json> [--menus-only]   read that app's menus (+ visible controls)
//   ScreenGuide.app                                menu bar app; asks for Accessibility permission

let args = CommandLine.arguments

func axTrusted(prompt: Bool) -> Bool {
    let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
}

func writeJSON<T: Encodable>(_ value: T, to path: String) {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try? enc.encode(value).write(to: URL(fileURLWithPath: path))
}

if let i = args.firstIndex(of: "--dump"), args.count > i + 2 {
    let appName = args[i + 1], out = args[i + 2]
    guard axTrusted(prompt: true) else {
        writeJSON(["error": "accessibility-not-granted"], to: out)
        exit(2)
    }
    guard let target = NSWorkspace.shared.runningApplications.first(where: {
        $0.localizedName?.caseInsensitiveCompare(appName) == .orderedSame || $0.bundleIdentifier == appName
    }) else {
        writeJSON(["error": "app-not-running: \(appName)"], to: out)
        exit(3)
    }
    writeJSON(AXReader.snapshot(of: target, includeControls: !args.contains("--menus-only")), to: out)
    exit(0)
}

// Default: minimal menu bar app so macOS lists us under Accessibility.
final class AppDelegate: NSObject, NSApplicationDelegate {
    var item: NSStatusItem!
    func applicationDidFinishLaunching(_ n: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: "Screen Guide")
        let menu = NSMenu()
        let status = NSMenuItem(title: axTrusted(prompt: true) ? "Accessibility: on" : "Accessibility: needs permission", action: nil, keyEquivalent: "")
        menu.addItem(status)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
