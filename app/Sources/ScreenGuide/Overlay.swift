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
    @Published var askWorked = false              // a yes/no question card ("Did that do it?", "Is it working now?")
    @Published var yesLabel = "Yes, it works"
    @Published var noLabel = "Still not working"
    @Published var plan = ""                      // step 1 only: what we're doing overall (Apple on-device model)
    @Published var spotlight = false
    @Published var showDone = false               // text-entry steps: user says when they've typed
    /// Top-left of the display the overlay is on, in AX coordinates (targets can be on any display).
    @Published var origin: CGPoint = .zero
    @Published var arrowEdge: ArrowEdge = .none   // which card edge points at the ring
    @Published var arrowOffset: CGFloat = 0
}

// MARK: - Ring layer

struct RingLayer: View {
    @ObservedObject var model: OverlayModel

    /// Global AX rect -> this display's window coordinates.
    func local(_ r: CGRect) -> CGRect { r.offsetBy(dx: -model.origin.x, dy: -model.origin.y) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if model.spotlight, let g = model.target {
                let t = local(g)
                SpotlightShape(hole: t.insetBy(dx: -10, dy: -10)).fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
                    .transition(.opacity.animation(.easeInOut(duration: 0.6)))
            }
            if let g = model.target, [.guiding, .confirmed, .detour].contains(model.mode) {
                let t = local(g)
                let ok = model.mode == .confirmed
                BreathingRing(rect: t, color: ok ? Theme.success : Theme.ring, stroke: model.spotlight ? 6 : 4, breathes: !ok)
                    .id("\(t)\(ok)")
                if ok {
                    let r = t.insetBy(dx: -Theme.ringPad, dy: -Theme.ringPad)
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 26)).foregroundStyle(.white, Theme.success)
                        .position(x: r.maxX, y: r.minY).transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            if model.mode == .notSure {
                ForEach(Array(model.candidates.map(local).enumerated()), id: \.offset) { i, c in
                    BreathingRing(rect: c, color: Theme.ring, stroke: 4, breathes: false, glow: false)
                    Text("\(i + 1)").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 30, height: 30).background(Circle().fill(Theme.ring))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .position(x: c.minX - 4, y: c.minY - 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.15), value: model.mode)
    }
}

/// 4pt outside the target: 1pt dark hairline, ring stroke (6 when stuck), 2pt white inner edge, soft glow.
/// Breathes 1.0→1.035 for three 2.4 s cycles, then holds still (design/gabay_v2).
struct BreathingRing: View {
    let rect: CGRect
    let color: Color
    let stroke: CGFloat
    var breathes = true
    var glow = true
    @State private var up = false
    @State private var arrived = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let r = rect.insetBy(dx: -Theme.ringPad, dy: -Theme.ringPad)
        let radius = min(r.height / 2, 10)
        ZStack {
            RoundedRectangle(cornerRadius: radius + 1, style: .continuous).stroke(Color.black.opacity(0.22), lineWidth: stroke + 2)
            RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(color, lineWidth: stroke)
            RoundedRectangle(cornerRadius: max(radius - stroke / 2, 2), style: .continuous).stroke(Color.white, lineWidth: 2)
                .padding(stroke / 2 + 1)
        }
        .frame(width: r.width, height: r.height)
        .shadow(color: glow ? color.opacity(up ? 0.55 : 0.38) : .clear, radius: 14)
        .scaleEffect(reduceMotion ? 1 : (!arrived ? 1.35 : up ? 1.035 : 1.0))
        .opacity(arrived ? 1 : 0)
        .position(x: r.midX, y: r.midY)
        .onAppear {
            // Lands on the target (shrinks in from a little larger), then breathes.
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { arrived = true }
            guard breathes else { return }
            // Three in-and-out cycles, then rest at the small size.
            withAnimation(.easeInOut(duration: 1.2).repeatCount(5, autoreverses: true).delay(0.35)) { up = true }
            Task { try? await Task.sleep(nanoseconds: 6_000_000_000); withAnimation(.easeInOut(duration: 1.2)) { up = false } }
        }
    }
}

struct SpotlightShape: Shape {
    let hole: CGRect
    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        p.addRoundedRect(in: hole, cornerSize: CGSize(width: 12, height: 12))
        return p
    }
}

// MARK: - Card

/// One sentence (key word bold), an optional second line, and quiet actions that appear on hover or after
/// 8 s without progress. A small arrow points at the ring, like NSPopover.
struct CardView: View {
    @ObservedObject var model: OverlayModel
    var onAgain: () -> Void = {}
    var onStuck: () -> Void = {}
    var onStop: () -> Void = {}
    var onDone: () -> Void = {}
    var onNotThis: () -> Void = {}
    var onStillBroken: () -> Void = {}
    var onYes: () -> Void = {}
    @State private var hovering = false
    @State private var idle = false
    @State private var showWhat = false
    @State private var appeared = false

    var warning: Bool { model.label == "Wait" }
    static let pad: CGFloat = 12   // transparent margin around the card, room for the arrow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if model.mode == .thinking {
                HStack(spacing: 12) {
                    Circle().fill(Theme.ring).frame(width: 18, height: 18)
                        .phaseAnimator([0.45, 1.0]) { v, o in v.opacity(o) } animation: { _ in .easeInOut(duration: 0.8) }
                    Text("Looking…").font(Theme.secondary()).foregroundStyle(.primary)
                }
            } else {
                if warning {
                    Image(systemName: "hand.raised.fill").font(.system(size: 22, weight: .semibold)).foregroundStyle(Theme.warning)
                        .padding(.bottom, 2)
                }
                if !model.plan.isEmpty {
                    Text(model.plan).font(Theme.small()).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true).padding(.bottom, 2)
                }
                if model.mode == .confirmed {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 26)).foregroundStyle(.white, Theme.success)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
                Text(styled(model.instruction, size: 26)).font(Theme.sentence()).tracking(-0.26)
                    .foregroundStyle(warning ? Color(hex: 0x1C1C1E) : .primary).fixedSize(horizontal: false, vertical: true)
                if !model.hint.isEmpty, model.mode != .done {
                    Text(styled(model.hint, size: 19)).font(Theme.secondary())
                        .foregroundStyle(warning ? Color(hex: 0x3A3A3C) : Color.primary.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if model.mode == .done, model.askWorked {
                    HStack(spacing: 8) {
                        primary(model.yesLabel, onYes)
                        pill(model.noLabel, onStillBroken)
                    }.padding(.top, 10)
                } else if model.mode == .done, model.label != "All done" {
                    if !model.hint.isEmpty {
                        Text(styled(model.hint, size: 19)).font(Theme.secondary()).foregroundStyle(Color.primary.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack { Spacer(); pill("Close", onStop) }.padding(.top, 6)
                } else if model.mode == .done {
                    HStack(alignment: .top) {
                        if !model.hint.isEmpty {
                            DisclosureGroup("What I did", isExpanded: $showWhat) {
                                Text(model.hint).font(Theme.small()).foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
                            }.font(Theme.small()).padding(.top, 12)
                        }
                        Spacer(minLength: 12)
                        pill("Close", onStop)
                    }.padding(.top, 6)
                }
                actions
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 18)
        .frame(width: width, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(warning ? AnyShapeStyle(Theme.warningSurface) : AnyShapeStyle(.regularMaterial))
                .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.16), radius: 16, y: 12)
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
        )
        .overlay(alignment: arrowAlignment) { arrow }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : (model.arrowEdge == .bottom ? -6 : 6))
        .scaleEffect(appeared ? 1 : 0.97)
        .padding(Self.pad)
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hovering = h } }
        .task(id: model.instruction + "\(model.mode)") {
            idle = false
            // Each new sentence slides in from the ring's side (fade + 6pt, spring 0.35/0.85).
            appeared = false
            try? await Task.sleep(nanoseconds: 20_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { appeared = true }
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            withAnimation(.easeOut(duration: 0.2)) { idle = true }
            // Still nothing after a while longer: dim the rest of the screen around the ring, once.
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            if model.mode == .guiding, !model.spotlight, !Task.isCancelled { onStuck() }
        }
    }

    /// Fits the text, never wider than 440pt (560 when stuck), never so narrow the actions wrap.
    var width: CGFloat {
        let maxW = (model.spotlight ? 560 : Theme.cardMaxWidth) * Theme.scale
        if model.mode == .thinking { return 200 * Theme.scale }
        func w(_ s: String, _ size: CGFloat, _ weight: NSFont.Weight) -> CGFloat {
            let f = NSFont.systemFont(ofSize: size * Theme.scale, weight: weight)
            return s.replacingOccurrences(of: "**", with: "").components(separatedBy: "\n")
                .map { ($0 as NSString).size(withAttributes: [.font: f]).width }.max() ?? 0
        }
        let text = max(w(model.instruction, 26, .heavy), model.mode == .done ? 0 : w(model.hint, 19, .regular))
        let hasActions = [.guiding, .detour, .notSure].contains(model.mode)   // room for Not this one · Stop · speaker
        // A yes/no card must fit both buttons on one row (labels + their padding + spacing + card padding).
        let ask = model.mode == .done && model.askWorked
            ? w(model.yesLabel, 17, .semibold) + 40 + w(model.noLabel, 17, .semibold) + 36 + 8 + 48 : 0
        return min(maxW, max((hasActions ? 340 : 160) * Theme.scale, ceil(text) + 48, ceil(ask)))
    }

    @ViewBuilder var actions: some View {
        let show = hovering || idle || model.spotlight || model.mode == .notSure || warning || model.showDone
        if model.mode != .done, show {
            HStack(spacing: 8) {
                if warning {
                    primary("I understand", onStop)
                } else {
                    if model.showDone { primary("Done", onDone) }
                    pill("Not this one", onNotThis)
                    pill("Stop", onStop)
                    Button(action: onAgain) {
                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 16, weight: .semibold)).foregroundStyle(.primary)
                            .frame(width: 44, height: 44).background(Circle().fill(Color.primary.opacity(0.08)))
                    }.buttonStyle(.plain).help("Say it again")
                }
            }.padding(.top, 10).transition(.opacity)
        }
    }

    var arrowAlignment: Alignment {
        switch model.arrowEdge {
        case .top, .leading, .none: return .topLeading
        case .bottom: return .bottomLeading
        case .trailing: return .topTrailing
        }
    }

    @ViewBuilder var arrow: some View {
        if model.arrowEdge != .none, model.mode != .thinking {
            let fill = warning ? AnyShapeStyle(Theme.warningSurface) : AnyShapeStyle(.regularMaterial)
            let a = model.arrowOffset
            switch model.arrowEdge {
            case .top: Arrow(edge: .top).fill(fill).frame(width: 22, height: 12).offset(x: a - 11, y: -11.5)
            case .bottom: Arrow(edge: .bottom).fill(fill).frame(width: 22, height: 12).offset(x: a - 11, y: 11.5)
            case .leading: Arrow(edge: .leading).fill(fill).frame(width: 12, height: 22).offset(x: -11.5, y: a - 11)
            case .trailing: Arrow(edge: .trailing).fill(fill).frame(width: 12, height: 22).offset(x: 11.5, y: a - 11)
            case .none: EmptyView()
            }
        }
    }

    func pill(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(Theme.button()).foregroundStyle(.primary)
                .padding(.horizontal, 18).frame(height: 44)
                .background(Capsule().fill(Color.primary.opacity(0.08)))
                .contentShape(Capsule())
        }.buttonStyle(.plain)
    }

    func primary(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(Theme.button()).foregroundStyle(.white)
                .padding(.horizontal, 20).frame(height: 44)
                .background(Capsule().fill(warning ? Theme.warning : Theme.ring))
                .contentShape(Capsule())
        }.buttonStyle(.plain)
    }

    /// "Click **Tools**." -> key word heavier, in the text color (not tinted, so contrast stays high).
    func styled(_ s: String, size: CGFloat) -> AttributedString {
        var out = AttributedString()
        for (i, part) in s.components(separatedBy: "**").enumerated() {
            var a = AttributedString(part)
            if i % 2 == 1 { a.font = .system(size: size * Theme.scale, weight: .heavy) }
            out += a
        }
        return out
    }
}

enum ArrowEdge { case none, top, bottom, leading, trailing }

/// Popover arrow; `edge` is the card edge it sticks out of (it points away from the card).
struct Arrow: Shape {
    let edge: ArrowEdge
    func path(in r: CGRect) -> Path {
        var p = Path()
        switch edge {
        case .top: p.move(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        case .bottom: p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        case .leading: p.move(to: CGPoint(x: r.maxX, y: r.minY)); p.addLine(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        case .trailing: p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY)); p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        case .none: break
        }
        p.closeSubpath()
        return p
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
    var onNotThis: () -> Void = {}
    var onStillBroken: () -> Void = {}
    var onYes: () -> Void = {}
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
                                                    onDone: { [weak self] in self?.onDone() },
                                                    onNotThis: { [weak self] in self?.onNotThis() },
                                                    onStillBroken: { [weak self] in self?.onStillBroken() },
                                                    onYes: { [weak self] in self?.onYes() }))
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

    /// A display's frame in AX coordinates (top-left origin of the primary display, y down).
    func axFrame(_ s: NSScreen) -> CGRect {
        CGRect(x: s.frame.minX, y: primary.frame.height - s.frame.maxY, width: s.frame.width, height: s.frame.height)
    }

    /// The display holding the target; with nothing to point at, the one the mouse is on.
    var current: NSScreen {
        if let t = model.target ?? model.candidates.first {
            let c = CGPoint(x: t.midX, y: t.midY)
            if let s = NSScreen.screens.first(where: { axFrame($0).contains(c) }) { return s }
        }
        let m = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(m) }) ?? primary
    }

    func show() {
        let screen = current
        if model.origin != axFrame(screen).origin { model.origin = axFrame(screen).origin }
        ringWindow.setFrame(screen.frame, display: true)
        ringWindow.orderFrontRegardless()
        placeCard()
        cardWindow.orderFrontRegardless()
    }

    func hide() {
        model.mode = .hidden
        ringWindow.orderOut(nil)
        cardWindow.orderOut(nil)
    }

    /// Below → right → left → above the target, ~20pt from the ring, never over the target (+24pt) or any
    /// keep-out rect (open menus, the box being typed in); top-center if there's no target. The arrow
    /// points at the ring when the card sits beside it.
    func placeCard() {
        cardHost.layoutSubtreeIfNeeded()
        let size = cardHost.fittingSize
        let pad = CardView.pad
        let primaryH = primary.frame.height
        let on = current, vf = on.visibleFrame
        let vis = CGRect(x: vf.minX, y: primaryH - vf.maxY, width: vf.width, height: vf.height)   // AX coords, that display minus menu bar/Dock
        // Nothing to point at: speak from Gabay's corner, above its button, not over the app.
        var origin = CGPoint(x: vis.maxX - size.width - 4, y: vis.maxY - size.height - 84)
        var edge = ArrowEdge.none
        if let t = model.target {
            let block = [t.insetBy(dx: -20, dy: -20)] + keepOut.map { $0.insetBy(dx: -8, dy: -8) }
            let g = Theme.gap + Theme.ringPad - pad
            let options: [(CGPoint, ArrowEdge)] = [
                (CGPoint(x: t.midX - 48 - pad, y: t.maxY + g), .top),                          // below
                (CGPoint(x: t.maxX + g, y: t.midY - size.height / 2), .leading),                // right
                (CGPoint(x: t.minX - g - size.width, y: t.midY - size.height / 2), .trailing),  // left
                (CGPoint(x: t.midX - 48 - pad, y: t.minY - g - size.height), .bottom),          // above
            ]
            for (var o, e) in options {
                o.x = min(max(o.x, vis.minX + 8 - pad), vis.maxX - size.width - 8 + pad)
                o.y = min(max(o.y, vis.minY + 8 - pad), vis.maxY - size.height - 8 + pad)
                let card = CGRect(origin: o, size: size).insetBy(dx: pad, dy: pad)
                if !block.contains(where: { $0.intersects(card) }) { origin = o; edge = e; break }
            }
            let card = CGRect(origin: origin, size: size).insetBy(dx: pad, dy: pad)
            switch edge {
            case .top, .bottom:
                let a = t.midX - card.minX
                if a >= 24 && a <= card.width - 24 { model.arrowOffset = a } else { edge = .none }
            case .leading, .trailing:
                let a = t.midY - card.minY
                if a >= 24 && a <= card.height - 24 { model.arrowOffset = a } else { edge = .none }
            case .none: break
            }
        }
        if model.arrowEdge != edge { model.arrowEdge = edge }
        // AX (top-left) -> AppKit (bottom-left)
        let nsY = primaryH - origin.y - size.height
        cardWindow.setFrame(NSRect(x: origin.x, y: nsY, width: size.width, height: size.height), display: true)
    }

    /// The card's rect in AX coordinates (clicks on its buttons aren't clicks "somewhere else").
    var cardFrame: CGRect {
        guard cardWindow.isVisible else { return .null }
        let f = cardWindow.frame, h = primary.frame.height
        return CGRect(x: f.minX, y: h - f.maxY, width: f.width, height: f.height)
    }

    func update() {
        if model.mode == .hidden { hide(); return }
        show()
    }
}
