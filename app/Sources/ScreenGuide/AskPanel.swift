import AppKit
import SwiftUI

/// Design A "2a Ask": a glass panel under the menu bar icon.
struct AskView: View {
    @State private var text = ""
    var userName = "there"
    var onAsk: (String) -> Void
    let suggestions = ["Make a photo smaller to email it", "Make the screen brighter", "Connect to Wi-Fi"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hi \(userName).").font(.system(size: 17)).foregroundStyle(Theme.inkSoft)
            Text("What would you like to do?").font(.system(size: 28, weight: .bold)).foregroundStyle(Theme.ink)
            HStack(spacing: 10) {
                TextField("Type it here", text: $text)
                    .textFieldStyle(.plain).font(.system(size: 20))
                    .padding(.horizontal, 18).frame(height: 58)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.85)))
                    .onSubmit { submit(text) }
                Button { submit(text) } label: {
                    Image(systemName: "arrow.up").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 58, height: 58).background(Circle().fill(Theme.beacon))
                }.buttonStyle(.plain)
            }
            Text("YOU COULD SAY").font(Theme.label()).tracking(0.8).foregroundStyle(Theme.inkSoft).padding(.top, 4)
            ForEach(suggestions, id: \.self) { s in
                Button { submit(s) } label: {
                    Text("“\(s)”").font(.system(size: 17)).foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.05)))
                }.buttonStyle(.plain)
            }
            HStack(spacing: 8) {
                Circle().fill(Theme.done).frame(width: 8, height: 8)
                Text("Private. Works without the internet.").font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
            }.padding(.top, 6)
        }
        .padding(28)
        .frame(width: 440)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous).fill(.regularMaterial)
                .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Color.white.opacity(0.55)))
                .shadow(color: .black.opacity(0.25), radius: 25, y: 18)
        )
        .environment(\.colorScheme, .light)
    }

    func submit(_ s: String) {
        let t = s.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty { onAsk(t) }
    }
}

/// Key-capable panel (it needs typing) that doesn't show in the Dock or app switcher.
final class AskPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    init(onAsk: @escaping (String) -> Void) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 440, height: 420),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar
        hidesOnDeactivate = false
        contentView = NSHostingView(rootView: AskView(onAsk: onAsk))
    }

    /// Anchor under the menu bar, near the right edge (design: right 70 / top 36).
    func present() {
        guard let screen = NSScreen.screens.first else { return }
        let size = contentView?.fittingSize ?? NSSize(width: 440, height: 420)
        setFrame(NSRect(x: screen.frame.maxX - size.width - 70, y: screen.visibleFrame.maxY - size.height - 12,
                        width: size.width, height: size.height), display: true)
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }
}
