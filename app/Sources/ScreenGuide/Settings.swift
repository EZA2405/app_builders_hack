import AppKit
import SwiftUI

/// The three things a person might want to change. Stored in UserDefaults; applied to Theme right away.
final class Prefs: ObservableObject {
    static let shared = Prefs()
    private let d = UserDefaults.standard

    @Published var textSize: Int { didSet { d.set(textSize, forKey: "textSize"); apply() } }     // 0 Large, 1 Larger, 2 Largest
    @Published var readAloud: Bool { didSet { d.set(readAloud, forKey: "readAloud") } }
    @Published var ringColor: String { didSet { d.set(ringColor, forKey: "ringColor"); apply() } }

    static let sizes: [(String, CGFloat)] = [("Large", 1.0), ("Larger", 1.15), ("Largest", 1.38)]

    private init() {
        textSize = d.object(forKey: "textSize") as? Int ?? 0
        readAloud = d.object(forKey: "readAloud") as? Bool ?? true
        ringColor = d.string(forKey: "ringColor") ?? "Purple"
        apply()
    }

    func apply() {
        Theme.scale = Self.sizes[min(max(textSize, 0), 2)].1
        Theme.ring = Color(hex: Theme.ringChoices[ringColor] ?? 0xAF52DE)
    }
}

struct SettingsView: View {
    @ObservedObject var prefs = Prefs.shared
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Settings").font(.system(size: 26, weight: .bold))

            section("Text size") {
                HStack(spacing: 8) {
                    ForEach(Array(Prefs.sizes.enumerated()), id: \.offset) { i, s in
                        choice(selected: prefs.textSize == i) { prefs.textSize = i } label: {
                            Text(s.0).font(.system(size: 15 * s.1, weight: .semibold))
                        }
                    }
                }
            }

            section("Read aloud") {
                Toggle(isOn: $prefs.readAloud) {
                    Text("Say each step out loud").font(.system(size: 17))
                }.toggleStyle(.switch).tint(Theme.ring).controlSize(.large)
            }

            section("Ring color") {
                HStack(spacing: 14) {
                    ForEach(["Purple", "Pink", "Orange"], id: \.self) { name in
                        Button { withAnimation(.spring(response: 0.3)) { prefs.ringColor = name } } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle().stroke(Color(hex: Theme.ringChoices[name]!), lineWidth: 5).frame(width: 34, height: 34)
                                    Circle().stroke(.white, lineWidth: 1.5).frame(width: 27, height: 27)
                                }
                                .padding(6)
                                .background(Circle().fill(Color.primary.opacity(prefs.ringColor == name ? 0.12 : 0)))
                                Text(name).font(.system(size: 14, weight: prefs.ringColor == name ? .semibold : .regular))
                            }
                        }.buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.system(size: 13))
                Text("Everything stays on this Mac. Nothing is sent anywhere.")
            }.font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button(action: onClose) {
                    Text("Done").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 24).frame(height: 44).background(Capsule().fill(Theme.ring))
                }.buttonStyle(.plain).keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 440)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(nsColor: .windowBackgroundColor).opacity(0.62)))
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 14)
        .padding(24)
        .onExitCommand(perform: onClose)
    }

    @ViewBuilder func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(.secondary)
            content()
        }
    }

    func choice<L: View>(selected: Bool, _ action: @escaping () -> Void, @ViewBuilder label: () -> L) -> some View {
        Button(action: { withAnimation(.spring(response: 0.3)) { action() } }) {
            label().foregroundStyle(selected ? .white : .primary)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(selected ? Theme.ring : Color.primary.opacity(0.07)))
        }.buttonStyle(.plain)
    }
}

/// First run: Gabay can't see the screen until the person turns on Accessibility for it. Walk them through it
/// in two plain steps and notice by itself when it's done.
struct WelcomeView: View {
    enum Step { case hello, toggle, ready }
    @State var step: Step = .hello
    var onShowMe: () -> Void
    var onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle().stroke(Theme.ring, lineWidth: 5).frame(width: 34, height: 34)
                Circle().stroke(.white, lineWidth: 1.5).frame(width: 26, height: 26)
                if step == .ready {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(.white, Theme.success)
                        .offset(x: 16, y: -14).transition(.scale.combined(with: .opacity))
                }
            }.padding(.bottom, 8)
            Group {
                switch step {
                case .hello:
                    Text("Welcome to Gabay").font(.system(size: 28, weight: .bold))
                    Text("Gabay shows you where to click. It needs permission to see your screen.")
                        .font(.system(size: 19)).foregroundStyle(.secondary)
                case .toggle:
                    Text(styled("Click the switch next to **Gabay**.")).font(.system(size: 26, weight: .semibold))
                    Text("If a box pops up, click Open System Settings. Your Mac may ask for your password.")
                        .font(.system(size: 19)).foregroundStyle(.secondary)
                case .ready:
                    Text("You're all set.").font(.system(size: 28, weight: .bold))
                    Text("Whenever you need help, click the Gabay button in the corner, or press Option + Space.")
                        .font(.system(size: 19)).foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 6)), removal: .opacity))
            HStack {
                Spacer()
                if step == .hello {
                    primary("Show me how") { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step = .toggle }; onShowMe() }
                } else if step == .ready {
                    primary("Start") { onFinish() }
                } else {
                    HStack(spacing: 8) { ProgressView().controlSize(.small); Text("Waiting for the switch…") }
                        .font(.system(size: 15, weight: .medium)).foregroundStyle(.secondary).frame(height: 44)
                }
            }.padding(.top, 10)
        }
        .padding(28)
        .frame(width: 440, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(nsColor: .windowBackgroundColor).opacity(0.62)))
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 14)
        .padding(24)
        .task(id: step) {
            guard step == .toggle else { return }
            while !Task.isCancelled, !AXIsProcessTrusted() { try? await Task.sleep(nanoseconds: 700_000_000) }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { step = .ready }
        }
    }

    func primary(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                .padding(.horizontal, 24).frame(height: 44).background(Capsule().fill(Theme.ring))
        }.buttonStyle(.plain).keyboardShortcut(.defaultAction)
    }

    func styled(_ s: String) -> AttributedString {
        var out = AttributedString()
        for (i, part) in s.components(separatedBy: "**").enumerated() {
            var a = AttributedString(part)
            if i % 2 == 1 { a.font = .system(size: 26, weight: .heavy) }
            out += a
        }
        return out
    }
}

/// Borderless glass panel for Settings and Welcome, sitting above the Gabay button.
final class GlassPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    init<V: View>(_ view: V) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 488, height: 400),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .statusBar
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = NSHostingView(rootView: view)
    }

    func present() {
        guard let screen = NSScreen.screens.first else { return }
        let size = contentView?.fittingSize ?? NSSize(width: 488, height: 400)
        let v = screen.visibleFrame
        setFrame(NSRect(x: v.maxX - size.width - GabayButtonPanel.margin + 10, y: v.minY + 80 + GabayButtonPanel.margin,
                        width: size.width, height: size.height), display: true)
        alphaValue = 0
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { $0.duration = 0.25; animator().alphaValue = 1 }
    }

    func dismiss() {
        NSAnimationContext.runAnimationGroup({ $0.duration = 0.15; animator().alphaValue = 0 }) { [weak self] in self?.orderOut(nil) }
    }
}
