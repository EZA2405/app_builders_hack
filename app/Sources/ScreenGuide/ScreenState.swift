import AppKit
import ApplicationServices

/// One thing the user could act on anywhere on screen: a menu command, a control in a
/// window or dialog, a Dock icon, or a menu bar status icon. This is the candidate list
/// the local model chooses from, so navigation can cross windows and apps.
struct Candidate: Codable {
    var id: Int
    /// "menu", "window", "dock", "statusbar"
    var source: String
    var role: String
    var label: String
    /// Where it lives: menu path parent, dialog/pane title, "Dock", "Menu bar".
    var context: String
    /// Menu path for menu items ("Tools > Adjust Size…"); for others "<context> > <label>".
    var path: String
    var frame: [Double]?
    var enabled: Bool
    /// Switches and checkboxes: on or off (not personal; lets Gabay see a fix is already in place).
    var on: Bool? = nil
}

struct ScreenState: Codable {
    var frontApp: String
    var bundleID: String?
    var windowTitles: [String]
    var candidates: [Candidate]
    var readMillis: Int
}

enum ScreenReader {
    // Roles worth pointing at inside windows. AXRow covers sidebars and lists (System Settings panes).
    static let windowRoles: Set<String> = [
        "AXButton", "AXCheckBox", "AXRadioButton", "AXPopUpButton", "AXMenuButton", "AXTextField",
        "AXTextArea", "AXSearchField", "AXSlider", "AXComboBox", "AXLink", "AXDisclosureTriangle",
        "AXIncrementor", "AXColorWell", "AXSegmentedControl", "AXRow", "AXTab",
    ]
    // Never read what the user typed: these roles get a label from their title, never their value.
    static let textEntryRoles: Set<String> = ["AXTextField", "AXTextArea", "AXSearchField", "AXComboBox"]

    static func state(of app: NSRunningApplication, maxPerWindow: Int = 400) -> ScreenState {
        let start = Date()
        var out: [Candidate] = []
        var nextID = 1
        func add(_ c: Candidate) { var c = c; c.id = nextID; nextID += 1; out.append(c) }

        let root = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 1.0)

        // 1. Frontmost app's menus (reuses AXReader's walker, includes closed submenus).
        let snap = AXReader.snapshot(of: app, includeControls: false)
        for m in snap.commands {
            let parts = m.path.components(separatedBy: " > ")
            add(Candidate(id: 0, source: "menu", role: "menu item", label: m.label,
                          context: parts.dropLast().joined(separator: " > "), path: m.path,
                          frame: m.frame, enabled: m.enabled))
        }

        // 2. Every open window of the app, dialogs and sheets included.
        var titles: [String] = []
        for w in AXReader.children(root, kAXWindowsAttribute).prefix(4) {
            let sub = AXReader.string(w, kAXSubroleAttribute) ?? ""
            let name = AXReader.string(w, kAXTitleAttribute).flatMap { $0.isEmpty ? nil : $0 }
            // Titled dialogs ("Export") must still read as dialogs, or the guide looks past them at the window.
            let isDialog = sub == "AXDialog" || sub == "AXSystemDialog"
            let title = isDialog ? (name.map { "\($0) dialog" } ?? "dialog") : (name ?? "window")
            titles.append(name ?? title)
            var count = 0
            // Sheets first: they're what the person is looking at, and must not be cut off by the per-window limit.
            let kids = AXReader.children(w)
            for sheet in kids where AXReader.role(sheet) == "AXSheet" {
                walk(sheet, context: title, depth: 1, count: &count, limit: maxPerWindow) { add($0) }
            }
            for c in kids where AXReader.role(c) != "AXSheet" {
                walk(c, context: title, depth: 1, count: &count, limit: maxPerWindow) { add($0) }
            }
        }

        // 3. Dock icons (open or switch apps).
        if let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first {
            let d = AXUIElementCreateApplication(dock.processIdentifier)
            for list in AXReader.children(d) where AXReader.role(list) == "AXList" {
                for item in AXReader.children(list) {
                    guard let t = AXReader.string(item, kAXTitleAttribute) else { continue }
                    add(Candidate(id: 0, source: "dock", role: "dock icon", label: t, context: "Dock",
                                  path: "Dock > \(t)", frame: AXReader.visibleFrame(item), enabled: true))
                }
            }
        }

        // 4. Menu bar status icons (Wi-Fi, Bluetooth, Sound, Battery, Control Center, ...).
        for bid in ["com.apple.controlcenter", "com.apple.systemuiserver"] {
            guard let p = NSRunningApplication.runningApplications(withBundleIdentifier: bid).first else { continue }
            let e = AXUIElementCreateApplication(p.processIdentifier)
            guard let bar: AXUIElement = AXReader.attr(e, "AXExtrasMenuBar") else { continue }
            for item in AXReader.children(bar) {
                let t = AXReader.string(item, kAXDescriptionAttribute) ?? AXReader.string(item, kAXTitleAttribute) ?? ""
                if t.isEmpty { continue }
                add(Candidate(id: 0, source: "statusbar", role: "menu bar icon", label: t, context: "Menu bar",
                              path: "Menu bar > \(t)", frame: AXReader.visibleFrame(item), enabled: true))
            }
        }

        return ScreenState(frontApp: app.localizedName ?? "?", bundleID: app.bundleIdentifier,
                           windowTitles: titles, candidates: out,
                           readMillis: Int(Date().timeIntervalSince(start) * 1000))
    }

    private static func walk(_ el: AXUIElement, context: String, depth: Int, count: inout Int, limit: Int,
                             emit: (Candidate) -> Void) {
        guard depth < 30, count < limit else { return }
        let r = AXReader.role(el) ?? ""
        var ctx = context
        // Named containers become context ("Adjust Size" sheet, "Display" group, sidebar...).
        if ["AXSheet", "AXGroup", "AXTabGroup", "AXScrollArea", "AXSplitGroup", "AXOutline", "AXTable"].contains(r),
           let name = AXReader.string(el, kAXTitleAttribute) ?? AXReader.string(el, kAXDescriptionAttribute) {
            ctx = String(name.prefix(40))
        }
        if r == "AXSheet" { ctx = ctx == context ? "\(context) dialog" : "\(ctx) dialog" }   // always a dialog, named or not

        // An open pop-up list ("JPEG", "PNG"…): each choice is a step of its own.
        if r == "AXMenuItem" {
            if let frame = AXReader.visibleFrame(el), let t = AXReader.string(el, kAXTitleAttribute), !t.isEmpty {
                emit(Candidate(id: 0, source: "window", role: "list choice", label: clip(t), context: ctx,
                               path: "\(ctx) > \(t)", frame: frame, enabled: AXReader.bool(el, kAXEnabledAttribute) ?? true))
                count += 1
            }
            return
        }
        var childCtx = ctx
        if windowRoles.contains(r), let frame = AXReader.visibleFrame(el) {
            var label = label(of: el, role: r)
            // Fields often have no linked title, just a static text beside them ("Width:").
            if label.isEmpty, textEntryRoles.contains(r) || r == "AXPopUpButton" || r == "AXSlider",
               let near = precedingText(el) { label = near }
            // A pop-up's title is its current choice ("TIFF"); the text beside it says what it is ("Format:").
            if r == "AXPopUpButton", let near = precedingText(el), near != label {
                label = near.trimmingCharacters(in: CharacterSet(charactersIn: ": "))
            }
            if !label.isEmpty {
                let sub = AXReader.string(el, kAXSubroleAttribute)
                let role = sub == "AXSwitch" ? "switch" : friendly(r)
                var cand = Candidate(id: 0, source: "window", role: role, label: label, context: ctx,
                                     path: "\(ctx) > \(label)", frame: frame,
                                     enabled: AXReader.bool(el, kAXEnabledAttribute) ?? true)
                if r == "AXCheckBox", let v: NSNumber = AXReader.attr(el, kAXValueAttribute) { cand.on = v.boolValue }
                emit(cand)
                count += 1
            }
            if r == "AXRow" { return } // a row's own text is its label; don't descend
            if r == "AXPopUpButton", !label.isEmpty { childCtx = "\(label) list" }
        }
        for c in AXReader.children(el) {
            walk(c, context: childCtx, depth: depth + 1, count: &count, limit: limit, emit: emit)
        }
    }

    static func label(of el: AXUIElement, role r: String) -> String {
        if let t = AXReader.string(el, kAXTitleAttribute) { return clip(t) }
        if let d = AXReader.string(el, kAXDescriptionAttribute) { return clip(d) }
        if let tu: AXUIElement = AXReader.attr(el, kAXTitleUIElementAttribute),
           let t = AXReader.string(tu, kAXValueAttribute) ?? AXReader.string(tu, kAXTitleAttribute) { return clip(t) }
        if let ph = AXReader.string(el, kAXPlaceholderValueAttribute) { return clip(ph) }
        if r == "AXRow" { return clip(rowText(el)) }
        if let h = AXReader.string(el, kAXHelpAttribute) { return clip(h) }
        // Pop-ups show their selected option (e.g. "Pixels"); text entry never exposes its value.
        if !textEntryRoles.contains(r), let v: String = AXReader.attr(el, kAXValueAttribute), !v.isEmpty { return clip(v) }
        return ""
    }

    /// The visual label of a field: the static text in the same container that sits on the
    /// same row and closest to its left ("Width:"), falling back to the nearest text above.
    static func precedingText(_ el: AXUIElement) -> String? {
        guard let parent: AXUIElement = AXReader.attr(el, kAXParentAttribute),
              let f = AXReader.visibleFrame(el) else { return nil }
        let midY = f[1] + f[3] / 2
        var best: (score: Double, text: String)?
        for c in AXReader.children(parent) where AXReader.role(c) == "AXStaticText" {
            guard let v: String = AXReader.attr(c, kAXValueAttribute), !v.isEmpty,
                  let t = AXReader.visibleFrame(c) else { continue }
            let tMid = t[1] + t[3] / 2
            let gapX = f[0] - (t[0] + t[2])            // text should end left of the field
            let dy = abs(tMid - midY)
            var score: Double
            if dy < f[3] * 0.6 && gapX >= -4 { score = gapX }        // same row, to the left
            else if t[1] + t[3] <= f[1] + 2 && abs(t[0] - f[0]) < 40 { score = 1000 + (f[1] - t[1]) } // just above
            else { continue }
            if best == nil || score < best!.score { best = (score, v) }
        }
        return best.map { clip($0.text.trimmingCharacters(in: CharacterSet(charactersIn: ": "))) }
    }

    /// DEV ONLY: press a visible button in the app's windows by its label (e.g. "Cancel").
    static func pressButton(_ app: NSRunningApplication, label: String) -> Bool {
        let root = AXUIElementCreateApplication(app.processIdentifier)
        var visited = 0
        func find(_ el: AXUIElement, _ d: Int) -> AXUIElement? {
            visited += 1
            if d > 12 || visited > 3000 { return nil }   // never crawl a whole file browser
            if AXReader.role(el) == "AXButton",
               (AXReader.string(el, kAXTitleAttribute) ?? AXReader.string(el, kAXDescriptionAttribute))?.caseInsensitiveCompare(label) == .orderedSame { return el }
            if AXReader.role(el) == "AXOutline" || AXReader.role(el) == "AXTable" || AXReader.role(el) == "AXBrowser" { return nil }
            for c in AXReader.children(el) { if let f = find(c, d + 1) { return f } }
            return nil
        }
        for w in AXReader.children(root, kAXWindowsAttribute) {
            if let b = find(w, 0) { return AXUIElementPerformAction(b, kAXPressAction as CFString) == .success }
        }
        return false
    }

    static func rowText(_ el: AXUIElement, depth: Int = 0) -> String {
        guard depth < 4 else { return "" }
        for c in AXReader.children(el) {
            if AXReader.role(c) == "AXStaticText", let v: String = AXReader.attr(c, kAXValueAttribute), !v.isEmpty { return v }
            let t = rowText(c, depth: depth + 1)
            if !t.isEmpty { return t }
        }
        return ""
    }

    static func clip(_ s: String) -> String {
        // "Camera, 10" (a count of apps) reads as part of the name; keep just "Camera".
        let t = s.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: #",\s*\d+$"#, with: "", options: .regularExpression)
        return String(t.prefix(60))
    }

    static func friendly(_ r: String) -> String {
        ["AXButton": "button", "AXCheckBox": "checkbox", "AXRadioButton": "option", "AXPopUpButton": "pop-up menu",
         "AXMenuButton": "menu button", "AXTextField": "text field", "AXTextArea": "text area", "AXSearchField": "search field",
         "AXSlider": "slider", "AXComboBox": "combo box", "AXLink": "link", "AXDisclosureTriangle": "disclosure",
         "AXIncrementor": "stepper", "AXColorWell": "color well", "AXSegmentedControl": "segmented control",
         "AXRow": "row", "AXTab": "tab"][r] ?? r
    }

    /// DEV ONLY (data collection): press a menu item of `app` by exact menu path. The guide
    /// product never clicks for the user; this exists so we can open dialogs to record them.
    static func pressMenu(_ app: NSRunningApplication, path: String) -> Bool {
        let root = AXUIElementCreateApplication(app.processIdentifier)
        guard let bar: AXUIElement = AXReader.attr(root, kAXMenuBarAttribute) else { return false }
        var parts = path.components(separatedBy: " > ")[...]
        var level: [AXUIElement] = AXReader.children(bar)
        while let name = parts.popFirst() {
            guard let hit = level.first(where: { AXReader.string($0, kAXTitleAttribute) == name }) else { return false }
            if parts.isEmpty { return AXUIElementPerformAction(hit, kAXPressAction as CFString) == .success }
            level = AXReader.children(hit).filter { AXReader.role($0) == "AXMenu" }.flatMap { AXReader.children($0) }
        }
        return false
    }
}
