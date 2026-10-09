import AppKit
import SwiftUI

/// What the overlay shows right now. Rects are in AX/global coordinates (top-left origin,
/// primary display), which match the overlay window's SwiftUI coordinates.
final class OverlayModel: ObservableObject {
    enum Mode { case hidden, thinking, guiding, confirmed, detour, notSure, done }
    @Published var mode: Mode = .hidden
    @Published var target: CGRect?
    @Published var candidates: [CGRect] = []      // not-sure mode
    @Published var label = ""                     // "STEP 1"
    @Published var instruction = ""               // may contain **bold** key word
    @Published var hint = ""
    @Published var spotlight = false
    @Published var showDone = false               // text-entry steps: user says when they've typed
}

// MARK: - Ring layer

struct RingLayer: View {
    @ObservedObject var model: OverlayModel
    @State private var breathe = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if model.spotlight, let t = model.target {
                SpotlightShape(hole: t.insetBy(dx: -8, dy: -8)).fill(Color.black.opacity(0.45), style: FillStyle(eoFill: true))
            }
            if let t = model.target, model.mode == .guiding || model.mode == .confirmed || model.mode == .detour {
                let color = model.mode == .confirmed ? Theme.done : Theme.beacon
                let r = t.insetBy(dx: -Theme.ringPad, dy: -Theme.ringPad)
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.white, lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 6).padding(-2))
                    .shadow(color: color.opacity(0.5), radius: 14)
                    .frame(width: r.width, height: r.height)
                    .scaleEffect(breathe ? 1.08 : 1.0)
                    .position(x: r.midX, y: r.midY)
                    .onAppear {
                        breathe = false
                        withAnimation(.easeInOut(duration: 0.8).repeatCount(6, autoreverses: true)) { breathe = true }
                    }
                if model.mode == .confirmed {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(.white, Theme.done)
                        .position(x: r.maxX, y: r.minY)
                }
            }
            if model.mode == .notSure {
                ForEach(Array(model.candidates.enumerated()), id: \.offset) { i, c in
                    let r = c.insetBy(dx: -4, dy: -4)
                    RoundedRectangle(cornerRadius: 8).stroke(Theme.beacon, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                        .frame(width: r.width, height: r.height).position(x: r.midX, y: r.midY)
                    Text("\(i + 1)").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 22, height: 22).background(Circle().fill(Theme.beacon))
                        .position(x: r.minX, y: r.minY)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

struct SpotlightShape: Shape {
    let hole: CGRect
    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        p.addRoundedRect(in: hole, cornerSize: CGSize(width: 10, height: 10))
        return p
    }
}

// MARK: - Card

struct CardView: View {
    @ObservedObject var model: OverlayModel
    var onAgain: () -> Void = {}
    var onStuck: () -> Void = {}
    var onStop: () -> Void = {}
    var onDone: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.label.uppercased())
                .font(Theme.label()).tracking(0.8)
                .foregroundStyle(labelColor)
            if model.mode == .thinking {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text(model.instruction).font(Theme.instruction())
                }
            } else {
                Text(styled(model.instruction)).font(Theme.instruction()).foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !model.hint.isEmpty {
                Text(model.hint).font(Theme.hint()).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if model.mode == .guiding || model.mode == .detour || model.mode == .notSure {
                HStack(spacing: 8) {
                    if model.showDone { primary("Done", onDone) }
                    pill("Say it again", onAgain)
                    pill("I'm stuck", onStuck)
                    Spacer()
                    pill("Stop", onStop)
                }.padding(.top, 4)
            }
            if model.mode == .done {
                HStack { Spacer(); pill("Close", onStop) }.padding(.top, 4)
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 20)
        .frame(width: Theme.cardWidth * Theme.scale, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(.regularMaterial)
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).fill(Color.white.opacity(0.55)))
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).stroke(Color.white.opacity(0.85), lineWidth: 1))
                .shadow(color: Color(red: 18/255, green: 22/255, blue: 40/255).opacity(0.28), radius: 25, y: 18)
        )
        .environment(\.colorScheme, .light)
    }

    var labelColor: Color {
        switch model.mode {
        case .confirmed, .done: return Theme.doneText
        case .detour: return Theme.detour
        default: return Theme.inkSoft
        }
    }

    func pill(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(Theme.button()).foregroundStyle(Theme.ink)
                .padding(.horizontal, 16).frame(height: 40)
                .background(Capsule().fill(Color.black.opacity(0.06)))
        }.buttonStyle(.plain)
    }

    func primary(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(Theme.button()).foregroundStyle(.white)
                .padding(.horizontal, 18).frame(height: 40)
                .background(Capsule().fill(Theme.ink))
        }.buttonStyle(.plain)
    }

    /// "Click **Tools** at the top" -> key word in Beacon Ink, semibold.
    func styled(_ s: String) -> AttributedString {
        var out = AttributedString()
        for (i, part) in s.components(separatedBy: "**").enumerated() {
            var a = AttributedString(part)
            if i % 2 == 1 { a.foregroundColor = Theme.beaconInk }
            out += a
        }
        return out
    }
}

// MARK: - Windows

final class OverlayController {
    let model = OverlayModel()
    private var ringWindow: NSPanel!
    private var cardWindow: NSPanel!
    private var cardHost: NSHostingView<CardView>!
    var onAgain: () -> Void = {}
    var onStuck: () -> Void = {}
    var onStop: () -> Void = {}
    var onDone: () -> Void = {}
    /// Extra rects the card must not cover (an open menu, the text a step refers to).
    var keepOut: [CGRect] = []

    // Above open menus, so the ring can sit on a menu item.
    private let level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)) + 1)
    private var primary: NSScreen { NSScreen.screens.first ?? NSScreen.main! }

    init() {
        let frame = primary.frame
        ringWindow = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        ringWindow.isOpaque = false
        ringWindow.backgroundColor = .clear
        ringWindow.hasShadow = false
        ringWindow.ignoresMouseEvents = true          // clicks always reach the real app
        ringWindow.level = level
        ringWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        ringWindow.contentView = NSHostingView(rootView: RingLayer(model: model))

        cardHost = NSHostingView(rootView: CardView(model: model, onAgain: { [weak self] in self?.onAgain() },
                                                    onStuck: { [weak self] in self?.onStuck() },
                                                    onStop: { [weak self] in self?.onStop() },
                                                    onDone: { [weak self] in self?.onDone() }))
        cardWindow = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 360, height: 200),
                             styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        cardWindow.isOpaque = false
        cardWindow.backgroundColor = .clear
        cardWindow.hasShadow = false
        cardWindow.level = level
        cardWindow.becomesKeyOnlyIfNeeded = true
        cardWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        cardWindow.contentView = cardHost
    }

    func show() {
        ringWindow.setFrame(primary.frame, display: true)
        ringWindow.orderFrontRegardless()
        placeCard()
        cardWindow.orderFrontRegardless()
    }

    func hide() {
        model.mode = .hidden
        ringWindow.orderOut(nil)
        cardWindow.orderOut(nil)
    }

    /// Design A placement: below → right → left → above the target, 12pt gap, never over
    /// the target (+24pt keep-out) or any extra keep-out rect; centered top if no target.
    func placeCard() {
        cardHost.layoutSubtreeIfNeeded()
        let size = cardHost.fittingSize
        let screen = primary.frame
        let vis = CGRect(x: 0, y: screen.height - primary.visibleFrame.maxY, width: screen.width,
                         height: primary.visibleFrame.height)   // AX coords, below the menu bar
        var origin = CGPoint(x: (screen.width - size.width) / 2, y: vis.minY + 40)
        if let t = model.target {
            let block = [t.insetBy(dx: -24, dy: -24)] + keepOut.map { $0.insetBy(dx: -8, dy: -8) }
            let g = Theme.gap + Theme.ringPad
            let options = [
                CGPoint(x: t.minX, y: t.maxY + g),                                  // below
                CGPoint(x: t.maxX + g, y: t.midY - size.height / 2),                // right
                CGPoint(x: t.minX - g - size.width, y: t.midY - size.height / 2),   // left
                CGPoint(x: t.minX, y: t.minY - g - size.height),                    // above
            ]
            for var o in options {
                o.x = min(max(o.x, vis.minX + 8), vis.maxX - size.width - 8)
                o.y = min(max(o.y, vis.minY + 8), vis.maxY - size.height - 8)
                let r = CGRect(origin: o, size: size)
                if !block.contains(where: { $0.intersects(r) }) { origin = o; break }
            }
        }
        // AX (top-left) -> AppKit (bottom-left)
        let nsY = screen.height - origin.y - size.height
        cardWindow.setFrame(NSRect(x: origin.x, y: nsY, width: size.width, height: size.height), display: true)
    }

    func update() {
        if model.mode == .hidden { hide(); return }
        show()
    }
}
