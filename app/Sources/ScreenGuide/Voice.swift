import AppKit
import AVFoundation
import Carbon
import Speech

/// Option+Space from any app opens the Ask panel. Carbon hot keys need no Accessibility permission.
final class HotKey {
    private var ref: EventHotKeyRef?
    private static var action: (() -> Void)?

    init(action: @escaping () -> Void) {
        HotKey.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { HotKey.action?() }
            return noErr
        }, 1, &spec, nil, nil)
        RegisterEventHotKey(UInt32(kVK_Space), UInt32(optionKey), EventHotKeyID(signature: OSType(0x4742_4159), id: 1),
                            GetApplicationEventTarget(), 0, &ref)
    }
}

/// Dictation for the Ask panel. On-device only: if this Mac can't recognize speech locally, it stays off
/// rather than sending the person's voice to a server.
@MainActor
final class Listener: ObservableObject {
    @Published var text = ""
    @Published var listening = false
    @Published var unavailable = false
    /// Called with the transcript once the person pauses.
    var onFinished: ((String) -> Void)?
    private let engine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    private var pause: Timer?

    func start() {
        guard !listening else { return }
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized { self.begin() } else { self.unavailable = true }
            }
        }
    }

    private func begin() {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else { unavailable = true; return }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        let input = engine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in request.append(buffer) }
        engine.prepare()
        do { try engine.start() } catch { input.removeTap(onBus: 0); unavailable = true; return }
        text = ""
        listening = true
        unavailable = false
        task = recognizer.recognitionTask(with: request) { result, error in
            DispatchQueue.main.async {
                if let result {
                    self.text = result.bestTranscription.formattedString
                    self.waitForPause()
                }
                if error != nil || result?.isFinal == true { self.finish() }
            }
        }
    }

    /// Older users speak slowly; 1.8 s of quiet means they're done.
    private func waitForPause() {
        pause?.invalidate()
        pause = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { _ in
            DispatchQueue.main.async { self.finish() }
        }
    }

    func finish() {
        guard listening else { return }
        let said = text.trimmingCharacters(in: .whitespaces)
        stop()
        if !said.isEmpty { onFinished?(said) }
    }

    func stop() {
        pause?.invalidate()
        guard listening else { return }
        listening = false
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil
    }
}

/// Hands a goal to the browser extension's helper (extension/mock/mock_app.py) on 127.0.0.1:47823.
enum BrowserGuide {
    static let browsers: Set<String> = ["com.google.Chrome", "com.google.Chrome.beta", "com.google.Chrome.canary",
                                        "org.chromium.Chromium", "com.microsoft.edgemac", "com.brave.Browser",
                                        "company.thebrowser.Browser", "company.thebrowser.dia"]

    /// False when the helper isn't running or no browser extension is connected; the caller falls back to native.
    static func send(_ goal: String) async -> Bool {
        var url = URLComponents(string: "http://127.0.0.1:47823/goal")!
        url.queryItems = [URLQueryItem(name: "text", value: goal)]
        var request = URLRequest(url: url.url!)
        // Web pages can't set custom headers on cross-origin requests, so this header proves it's us.
        request.setValue("1", forHTTPHeaderField: "X-Gabay")
        request.timeoutInterval = 2
        guard let (_, response) = try? await URLSession.shared.data(for: request) else { return false }
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
}
