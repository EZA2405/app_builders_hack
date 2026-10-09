import AppKit
import SwiftUI

final class AskState: ObservableObject {
    @Published var shown = false
}

/// Gabay v2 "Ask": one glass card that grows out of the Gabay button. Examples on top (they fold away
/// once you start typing), the field at the bottom next to the button, one mic.
struct AskView: View {
    var onSettings: () -> Void = {}
    @State private var text = ""
    @ObservedObject var listener: Listener
    @ObservedObject var state: AskState
    var onAsk: (String) -> Void
    var onClose: () -> Void = {}
    @FocusState private var focused: Bool
    let examples = ["Make a photo smaller to email it", "Make the words bigger", "Paano mag-email ng picture"]

    var showExamples: Bool { text.isEmpty && !listener.listening }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showExamples {
                VStack(alignment: .leading, spacing: 2) {
                    Text("You could say").font(Theme.small()).foregroundStyle(.secondary)
                        .padding(.horizontal, 14).padding(.bottom, 4)
                    ForEach(Array(examples.enumerated()), id: \.offset) { i, e in
                        ExampleRow(text: e) { submit(e) }
                            .opacity(state.shown ? 1 : 0).offset(y: state.shown ? 0 : 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.85).delay(0.08 + Double(i) * 0.05), value: state.shown)
                    }
                }
                .padding(.horizontal, 10).padding(.top, 16).padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
                Rectangle().fill(Color.primary.opacity(0.08)).frame(height: 1).padding(.horizontal, 20)
            }
            HStack(spacing: 14) {
                Circle().stroke(Theme.ring, lineWidth: 3).frame(width: 18, height: 18)
                TextField(listener.listening ? "I'm listening…" : "What do you need help with?", text: $text)
                    .textFieldStyle(.plain).font(Theme.askField()).tint(Theme.ring)
                    .focused($focused)
                    .onSubmit { submit(text) }
                    .onChange(of: listener.text) { _, said in text = said }
                MicButton(listening: listener.listening) { listener.listening ? listener.finish() : listener.start() }
            }
            .padding(.leading, 22).padding(.trailing, 10).frame(height: 68)
            HStack(spacing: 6) {
                Text(listener.unavailable ? "Voice isn't set up on this Mac. You can type." :
                        listener.listening ? "I'm listening. Take your time." : "Tap the microphone, or type.")
                Spacer()
                Image(systemName: "lock.fill").font(.system(size: 11 * Theme.scale))
                Text("On this Mac")
                Button(action: onSettings) { Image(systemName: "gearshape").font(.system(size: 15 * Theme.scale, weight: .medium)) }
                    .buttonStyle(.plain).help("Settings").padding(.leading, 8)
            }
            .font(.system(size: 14 * Theme.scale, weight: .medium)).foregroundStyle(.secondary)
            .padding(.horizontal, 22).padding(.bottom, 14)
        }
        .frame(width: 540 * Theme.scale)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color(nsColor: .windowBackgroundColor).opacity(0.62)))   // busy backgrounds stay readable
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 14)
        .scaleEffect(state.shown ? 1 : 0.6, anchor: .bottomTrailing)
        .opacity(state.shown ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: state.shown)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showExamples)
        .padding(24)   // room for the shadow; the window itself draws none
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)   // stays anchored as it shrinks
        .onChange(of: state.shown) { _, v in if v { text = ""; focused = true } }
        .onExitCommand { onClose() }
    }

    func submit(_ s: String) {
        listener.stop()
        let t = s.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty { onAsk(t) }
    }
}

struct ExampleRow: View {
    let text: String
    let action: () -> Void
    @State private var hovering = false
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "text.bubble").font(.system(size: 15, weight: .medium))
                    .foregroundStyle(hovering ? Theme.ring : .secondary)
                Text(text).font(.system(size: 18 * Theme.scale)).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ring)
                    .opacity(hovering ? 1 : 0)
            }
            .padding(.horizontal, 14).frame(height: 42)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.ring.opacity(hovering ? 0.12 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeOut(duration: 0.12)) { hovering = h } }
    }
}

struct MicButton: View {
    let listening: Bool
    let action: () -> Void
    @State private var hovering = false
    var body: some View {
        Button(action: action) {
            ZStack {
                if listening {
                    Circle().fill(Theme.ring.opacity(0.25)).frame(width: 64, height: 64)
                        .phaseAnimator([0.85, 1.1]) { v, s in v.scaleEffect(s) } animation: { _ in .easeInOut(duration: 0.9) }
                }
                Circle().fill(Theme.ring).frame(width: 48, height: 48)
                Image(systemName: listening ? "waveform" : "mic.fill").font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, isActive: listening)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 64, height: 64)
            .scaleEffect(hovering ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.spring(response: 0.25)) { hovering = h } }
        .help("Talk instead of typing")
    }
}

/// The always-there way in: a 60pt round button, bottom-right. Click it (or press Option + Space) to ask.
struct GabayButton: View {
    var onTap: () -> Void
    var onSettings: () -> Void = {}
    @State private var hovering = false
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle().fill(.regularMaterial)
                Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                Circle().stroke(Theme.ring, lineWidth: 4).frame(width: 26, height: 26)
                Circle().stroke(Color.white, lineWidth: 1.5).frame(width: 19, height: 19)
            }
            .frame(width: 60, height: 60)
            .shadow(color: .black.opacity(0.16), radius: 12, y: 8)
            .scaleEffect(hovering ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.spring(response: 0.3)) { hovering = h } }
        .help("Need help? Click here, or press Option + Space")
        .contextMenu {
            Button("Settings…", action: onSettings)
            Divider()
            Button("Quit Gabay") { NSApp.terminate(nil) }
        }
        .padding(10)
    }
}

final class GabayButtonPanel: NSPanel {
    init(onTap: @escaping () -> Void, onSettings: @escaping () -> Void) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 80, height: 80),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        contentView = NSHostingView(rootView: GabayButton(onTap: onTap, onSettings: onSettings))
    }

    static let margin: CGFloat = 14

    func place() {
        guard let screen = NSScreen.screens.first else { return }
        let v = screen.visibleFrame
        setFrameOrigin(NSPoint(x: v.maxX - frame.width - Self.margin, y: v.minY + Self.margin))
        orderFrontRegardless()
    }
}

/// Key-capable panel (it needs typing) that doesn't show in the Dock or app switcher.
final class AskPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    let listener = Listener()
    let state = AskState()

    init(onAsk: @escaping (String) -> Void, onSettings: @escaping () -> Void = {}) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 600, height: 340),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false   // the system shadow traces the transparent window as a jagged outline; SwiftUI draws ours
        level = .statusBar
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = NSHostingView(rootView: AskView(onSettings: { onSettings() }, listener: listener, state: state, onAsk: onAsk,
                                                      onClose: { [weak self] in self?.orderOut(nil) }))
        listener.onFinished = { [weak self] said in
            guard let self, self.isVisible else { return }
            onAsk(said)
        }
    }

    /// Shrinks back into the button, then goes away.
    override func orderOut(_ sender: Any?) {
        listener.stop()
        guard state.shown else { super.orderOut(sender); return }
        state.shown = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            guard let self, !self.state.shown else { return }
            self.reallyOrderOut()
        }
    }

    private func reallyOrderOut() { super.orderOut(nil) }

    /// Grows out of the Gabay button: bottom-right, its right edge lined up with the button.
    /// `listen`: start dictation right away (opened with the hot key).
    func present(listen: Bool = false) {
        guard let screen = NSScreen.screens.first else { return }
        let v = screen.visibleFrame
        let size = NSSize(width: 540 * Theme.scale + 48, height: 340 * Theme.scale)
        setFrame(NSRect(x: v.maxX - size.width - 64 - GabayButtonPanel.margin, y: v.minY + GabayButtonPanel.margin - 14,
                        width: size.width, height: size.height), display: true)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        DispatchQueue.main.async { self.state.shown = true }
        if listen { listener.start() }
    }
}
