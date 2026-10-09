import AppKit

/// Watches the person's own clicks and Return presses anywhere on screen, so a step only counts
/// when they clicked inside the ring (or pressed Enter in the highlighted box). Points are in
/// AX/global coordinates (top-left origin of the primary display), same as the ring.
@MainActor
final class ClickWatcher {
    static let shared = ClickWatcher()
    enum Event { case click(CGPoint), enter }
    private var events: [Event] = []
    private var monitors: [Any] = []

    func start() {
        guard monitors.isEmpty else { return }
        let h = NSScreen.screens.first?.frame.height ?? 0
        if let m = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown], handler: { _ in
            let p = NSEvent.mouseLocation   // AppKit: bottom-left origin
            Task { @MainActor in ClickWatcher.shared.events.append(.click(CGPoint(x: p.x, y: h - p.y))) }
        }) { monitors.append(m) }
        if let k = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown], handler: { e in
            guard e.keyCode == 36 || e.keyCode == 76 else { return }   // Return / keypad Enter only; never the text
            Task { @MainActor in ClickWatcher.shared.events.append(.enter) }
        }) { monitors.append(k) }
    }

    func drain() -> [Event] { defer { events = [] }; return events }
}

extension CGRect {
    /// Generous hit area: older hands miss by a few points.
    func hit(_ p: CGPoint) -> Bool { insetBy(dx: -6, dy: -6).contains(p) }
}
