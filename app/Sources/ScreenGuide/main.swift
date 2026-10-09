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

func runningApp(_ name: String) -> NSRunningApplication? {
    if name == "frontmost" { return NSWorkspace.shared.frontmostApplication }
    return NSWorkspace.shared.runningApplications.first {
        $0.localizedName?.caseInsensitiveCompare(name) == .orderedSame || $0.bundleIdentifier == name
    }
}

//   ScreenGuide.app --screen <AppName|frontmost> <out.json>   full candidate list: menus, windows, Dock, status icons
if let i = args.firstIndex(of: "--screen"), args.count > i + 2 {
    guard axTrusted(prompt: true) else { writeJSON(["error": "accessibility-not-granted"], to: args[i + 2]); exit(2) }
    guard let target = runningApp(args[i + 1]) else { writeJSON(["error": "app-not-running: \(args[i + 1])"], to: args[i + 2]); exit(3) }
    writeJSON(ScreenReader.state(of: target), to: args[i + 2])
    exit(0)
}

//   ScreenGuide.app --press <AppName> "<Menu > Item>" <out.json>   DEV ONLY: open a dialog for data
//   collection, wait, then record the resulting screen state (with "pressed": true/false).
if let i = args.firstIndex(of: "--press"), args.count > i + 3 {
    guard axTrusted(prompt: true), let target = runningApp(args[i + 1]) else { exit(3) }
    target.activate()
    let what = args[i + 2]
    let ok = what.hasPrefix("button:") ? ScreenReader.pressButton(target, label: String(what.dropFirst(7)))
                                       : ScreenReader.pressMenu(target, path: what)
    Thread.sleep(forTimeInterval: 1.5)
    struct Pressed: Encodable { let pressed: Bool; let state: ScreenState }
    writeJSON(Pressed(pressed: ok, state: ScreenReader.state(of: target)), to: args[i + 3])
    exit(ok ? 0 : 4)
}

// Default: Gabay, the menu bar guide.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var item: NSStatusItem!
    let engine = GuideEngine()
    var ask: AskPanel!
    var hotKey: HotKey?
    /// The app the user was in before opening Gabay: that's the one we guide.
    var lastApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ n: Notification) {
        _ = axTrusted(prompt: true)
        lastApp = NSWorkspace.shared.frontmostApplication
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                                                          object: nil, queue: .main) { [weak self] note in
            // Only apps with windows and a Dock icon; system pop-ups (e.g. the Accessibility prompt) aren't goals.
            guard let a = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  a.bundleIdentifier != Bundle.main.bundleIdentifier, a.activationPolicy == .regular else { return }
            MainActor.assumeIsolated { self?.lastApp = a }
        }
        ask = AskPanel { [weak self] goal in self?.begin(goal) }

        hotKey = HotKey { [weak self] in
            guard let self else { return }
            if self.ask.isVisible { self.ask.orderOut(nil) } else { self.ask.present(listen: true) }
        }

        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "circle.circle", accessibilityDescription: "Gabay")
        item.button?.target = self
        item.button?.action = #selector(toggleAsk)

        // DEV: ScreenGuide.app --guide <AppName> "<goal>" starts a session directly.
        if let i = args.firstIndex(of: "--guide"), args.count > i + 2, let target = runningApp(args[i + 1]) {
            engine.start(goal: args[i + 2], app: target)
        }
    }

    @objc func toggleAsk() {
        if ask.isVisible { ask.orderOut(nil) } else { ask.present() }
    }

    func begin(_ goal: String) {
        ask.orderOut(nil)
        guard let target = lastApp else { return }
        // In a browser, the page is guided by the ScreenGuide extension (through its helper); else natively.
        if BrowserGuide.browsers.contains(target.bundleIdentifier ?? "") {
            Task {
                if await BrowserGuide.send(goal) { target.activate() } else { engine.start(goal: goal, app: target) }
            }
            return
        }
        engine.start(goal: goal, app: target)
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { app.run() }
}
