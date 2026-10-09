import AppKit
import SwiftUI

/// Gabay v2 "Ask": the floating button grows into a pill. One field, one mic, nothing else to learn.
struct AskView: View {
    @State private var text = ""
    @ObservedObject var listener: Listener
    var onAsk: (String) -> Void
    var onClose: () -> Void = {}
    @FocusState private var focused: Bool
    let examples = ["Make a photo smaller to email it", "Make the words bigger", "Paano mag-email ng picture"]

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if text.isEmpty && !listener.listening {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You could say").font(Theme.small()).foregroundStyle(.secondary).padding(.leading, 14)
                    ForEach(examples, id: \.self) { e in
                        Button { submit(e) } label: {
                            Text(e).font(.system(size: 17 * Theme.scale)).foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 14).frame(height: 40)
                                .contentShape(Rectangle())
                        }.buttonStyle(ExampleStyle())
                    }
                }
                .padding(8)
                .frame(width: 380 * Theme.scale)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.regularMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.14), radius: 14, y: 8))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            HStack(spacing: 12) {
                Circle().stroke(Theme.ring, lineWidth: 3).frame(width: 18, height: 18).padding(.leading, 20)
                TextField(listener.listening ? "I'm listening…" : "What do you need help with?", text: $text)
                    .textFieldStyle(.plain).font(Theme.askField())
                    .focused($focused)
                    .onSubmit { submit(text) }
                    .onChange(of: listener.text) { _, said in text = said }
                Button { listener.listening ? listener.finish() : listener.start() } label: {
                    Image(systemName: listener.listening ? "waveform" : "mic.fill").font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative, isActive: listener.listening)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(Theme.ring))
                        .shadow(color: Theme.ring.opacity(listener.listening ? 0.6 : 0), radius: 10)
                }.buttonStyle(.plain).help("Talk instead of typing")
                .padding(.trailing, 7)
            }
            .frame(width: 560 * Theme.scale, height: 60)
            .background(Capsule().fill(.regularMaterial)
                .overlay(Capsule().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.16), radius: 16, y: 12)
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2))
            HStack(spacing: 14) {
                Text(listener.unavailable ? "Voice isn't set up on this Mac. You can type." :
                        listener.listening ? "I'm listening. Take your time." : "Tap the microphone, or type.")
                Label("On this Mac", systemImage: "lock.fill")
            }
            .font(.system(size: 14 * Theme.scale, weight: .medium)).foregroundStyle(.secondary)
            .padding(.horizontal, 14).frame(height: 30)
            .background(Capsule().fill(.regularMaterial))
            .padding(.trailing, 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)   // pill stays put when examples hide
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: text.isEmpty)
        .onAppear { focused = true }
        .onExitCommand { onClose() }
    }

    func submit(_ s: String) {
        listener.stop()
        let t = s.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty { text = ""; onAsk(t) }
    }
}

struct ExampleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(RoundedRectangle(cornerRadius: 10)
            .fill(Color.primary.opacity(configuration.isPressed ? 0.12 : 0.0)))
    }
}

/// The always-there way in: a 60pt round button, bottom-right. Click it (or press Option + Space) to ask.
struct GabayButton: View {
    var onTap: () -> Void
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
        .padding(10)
    }
}

final class GabayButtonPanel: NSPanel {
    init(onTap: @escaping () -> Void) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 80, height: 80),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        contentView = NSHostingView(rootView: GabayButton(onTap: onTap))
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

    init(onAsk: @escaping (String) -> Void) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 440, height: 420),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = NSHostingView(rootView: AskView(listener: listener, onAsk: onAsk, onClose: { [weak self] in self?.orderOut(nil) }))
        listener.onFinished = { [weak self] said in
            guard let self, self.isVisible else { return }
            onAsk(said)
        }
    }

    override func orderOut(_ sender: Any?) {
        listener.stop()
        super.orderOut(sender)
    }

    /// Grows out of the Gabay button: bottom-right, its right edge lined up with the button.
    /// `listen`: start dictation right away (opened with the hot key).
    func present(listen: Bool = false) {
        guard let screen = NSScreen.screens.first else { return }
        let size = contentView?.fittingSize ?? NSSize(width: 600, height: 300)
        let v = screen.visibleFrame
        setFrame(NSRect(x: v.maxX - size.width - 80 - GabayButtonPanel.margin, y: v.minY + GabayButtonPanel.margin - 6,
                        width: size.width, height: size.height), display: true)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        if listen { listener.start() }
    }
}
