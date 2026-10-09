import AppKit
import ApplicationServices

/// One thing on screen the user could act on, read from the accessibility tree.
struct ScreenElement: Codable {
    var id: Int
    var role: String
    var label: String
    /// Menu path ("Tools > Adjust Size…") for menu items; window path for others.
    var path: String
    /// Screen rect in global top-left coordinates. nil for closed menu items (not on screen).
    var frame: [Double]?
    var enabled: Bool
    var shortcut: String?
}

struct ScreenSnapshot: Codable {
    var app: String
    var bundleID: String?
    var windowTitle: String?
    var commands: [ScreenElement]   // full menu tree, visible or not
    var controls: [ScreenElement]   // controls visible in the app's windows
    var readMillis: Int
}

enum AXReader {
    static let actionableRoles: Set<String> = [
        "AXButton", "AXCheckBox", "AXRadioButton", "AXPopUpButton", "AXMenuButton",
        "AXTextField", "AXTextArea", "AXSearchField", "AXSlider", "AXComboBox",
        "AXLink", "AXDisclosureTriangle", "AXIncrementor", "AXColorWell", "AXSegmentedControl",
    ]

    static func snapshot(of app: NSRunningApplication, includeControls: Bool = true) -> ScreenSnapshot {
        let start = Date()
        let root = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(root, 1.0)

        var nextID = 1
        var commands: [ScreenElement] = []
        if let menuBar: AXUIElement = attr(root, kAXMenuBarAttribute) {
            for item in children(menuBar) {
                let title = string(item, kAXTitleAttribute) ?? ""
                if title.isEmpty || title == "Apple" { continue }
                walkMenu(item, path: [title], into: &commands, nextID: &nextID)
            }
        }

        var controls: [ScreenElement] = []
        let window: AXUIElement? = attr(root, kAXFocusedWindowAttribute) ?? children(root, kAXWindowsAttribute).first
        if includeControls, let window {
            walkWindow(window, path: [], depth: 0, into: &controls, nextID: &nextID)
        }

        return ScreenSnapshot(
            app: app.localizedName ?? "?",
            bundleID: app.bundleIdentifier,
            windowTitle: window.flatMap { string($0, kAXTitleAttribute) },
            commands: commands,
            controls: controls,
            readMillis: Int(Date().timeIntervalSince(start) * 1000)
        )
    }

    // MARK: - Walkers

    private static func walkMenu(_ el: AXUIElement, path: [String], into out: inout [ScreenElement], nextID: inout Int) {
        // A menu bar item / submenu item holds one AXMenu child whose children are AXMenuItems.
        for menu in children(el) where role(menu) == "AXMenu" {
            for item in children(menu) {
                let title = string(item, kAXTitleAttribute) ?? ""
                if title.isEmpty { continue } // separator
                let itemPath = path + [title]
                let sub = children(item).contains { role($0) == "AXMenu" }
                if sub {
                    walkMenu(item, path: itemPath, into: &out, nextID: &nextID)
                } else {
                    out.append(ScreenElement(
                        id: nextID, role: "AXMenuItem", label: title,
                        path: itemPath.joined(separator: " > "),
                        frame: visibleFrame(item),
                        enabled: bool(item, kAXEnabledAttribute) ?? true,
                        shortcut: shortcut(item)))
                    nextID += 1
                }
            }
        }
    }

    private static func walkWindow(_ el: AXUIElement, path: [String], depth: Int, into out: inout [ScreenElement], nextID: inout Int) {
        guard depth < 30, out.count < 1500 else { return }
        let r = role(el) ?? ""
        let label = bestLabel(el)
        if actionableRoles.contains(r) {
            out.append(ScreenElement(
                id: nextID, role: r, label: label,
                path: (path + [label]).filter { !$0.isEmpty }.joined(separator: " > "),
                frame: visibleFrame(el),
                enabled: bool(el, kAXEnabledAttribute) ?? true,
                shortcut: nil))
            nextID += 1
        }
        // Containers with a name (toolbar, groups, tab groups) add context to the path.
        let containerName = ["AXToolbar", "AXTabGroup", "AXSheet", "AXGroup", "AXScrollArea"].contains(r) ? label : ""
        let childPath = containerName.isEmpty ? path : path + [containerName]
        for c in children(el) {
            walkWindow(c, path: r == "AXToolbar" && containerName.isEmpty ? path + ["Toolbar"] : childPath, depth: depth + 1, into: &out, nextID: &nextID)
        }
    }

    // MARK: - Attribute helpers

    static func attr<T>(_ el: AXUIElement, _ name: String) -> T? {
        var v: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success else { return nil }
        return v as? T
    }

    static func children(_ el: AXUIElement, _ name: String = kAXChildrenAttribute) -> [AXUIElement] {
        (attr(el, name) as [AXUIElement]?) ?? []
    }

    static func string(_ el: AXUIElement, _ name: String) -> String? {
        let s: String? = attr(el, name)
        return s?.isEmpty == false ? s : nil
    }

    static func bool(_ el: AXUIElement, _ name: String) -> Bool? { attr(el, name) }

    static func role(_ el: AXUIElement) -> String? { string(el, kAXRoleAttribute) }

    static func bestLabel(_ el: AXUIElement) -> String {
        string(el, kAXTitleAttribute)
            ?? string(el, kAXDescriptionAttribute)
            ?? string(el, kAXHelpAttribute)
            ?? (attr(el, kAXValueAttribute) as String?).flatMap { $0.isEmpty ? nil : String($0.prefix(60)) }
            ?? string(el, kAXRoleDescriptionAttribute)
            ?? ""
    }

    /// Frame in global screen coords (top-left origin), or nil if zero-sized / off-screen.
    static func visibleFrame(_ el: AXUIElement) -> [Double]? {
        guard let posV: AXValue = attr(el, kAXPositionAttribute),
              let sizeV: AXValue = attr(el, kAXSizeAttribute) else { return nil }
        var p = CGPoint.zero, s = CGSize.zero
        AXValueGetValue(posV, .cgPoint, &p)
        AXValueGetValue(sizeV, .cgSize, &s)
        guard s.width > 1, s.height > 1 else { return nil }
        return [p.x, p.y, s.width, s.height].map { (Double($0) * 10).rounded() / 10 }
    }

    static func shortcut(_ el: AXUIElement) -> String? {
        guard let ch = string(el, kAXMenuItemCmdCharAttribute) else { return nil }
        let mods = (attr(el, kAXMenuItemCmdModifiersAttribute) as Int?) ?? 0
        // kAXMenuItemModsNone = 0 means ⌘ only; bits: shift=1, option=2, control=4, noCommand=8
        var s = ""
        if mods & 4 != 0 { s += "⌃" }
        if mods & 2 != 0 { s += "⌥" }
        if mods & 1 != 0 { s += "⇧" }
        if mods & 8 == 0 { s += "⌘" }
        return s + ch
    }
}
