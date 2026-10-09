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
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognizer: SFSpeechRecognizer?
    private var pause: Timer?
    /// Text from earlier segments: the recognizer ends a segment at every pause, older people pause mid-sentence.
    private var committed = ""

    func start() {
        guard !listening else { return }
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized { self.begin() } else { self.unavailable = true }
            }
        }
    }

    private func begin() {
        // Philippine English understands the accent and common Tagalog words better than US English; both run
        // on-device here (Filipino itself has no on-device recognizer on macOS).
        let recognizer = [("en-PH"), ("en-US")].lazy.compactMap { SFSpeechRecognizer(locale: Locale(identifier: $0)) }
            .first { $0.isAvailable && $0.supportsOnDeviceRecognition }
        guard let recognizer else { unavailable = true; return }
        self.recognizer = recognizer
        let input = engine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        engine.prepare()
        do { try engine.start() } catch { input.removeTap(onBus: 0); unavailable = true; return }
        text = ""
        committed = ""
        listening = true
        unavailable = false
        segment()
    }

    /// One recognition segment. When the recognizer closes it at a pause, keep the words and open the next one;
    /// only our own 2.5 s quiet timer decides the person is done.
    private func segment() {
        guard listening, let recognizer else { return }
        let r = SFSpeechAudioBufferRecognitionRequest()
        r.requiresOnDeviceRecognition = true
        r.shouldReportPartialResults = true
        r.addsPunctuation = true
        r.taskHint = .dictation
        r.contextualStrings = Self.hints   // words people actually say to Gabay; biases recognition toward them
        request = r
        task = recognizer.recognitionTask(with: r) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self, self.listening else { return }
                if let result {
                    let seg = result.bestTranscription.formattedString
                    self.text = [self.committed, seg].filter { !$0.isEmpty }.joined(separator: " ")
                    self.waitForPause()
                    if result.isFinal { self.committed = self.text; self.segment() }
                } else if error != nil {
                    self.segment()   // a quiet segment can end with "no speech"; keep listening until our timer says done
                }
            }
        }
    }

    static let hints = ["Gabay", "anak", "apo", "Lola", "Lolo", "Nanay", "Tatay", "nakikita", "naririnig", "marinig",
                        "hindi daw", "hindi ko", "paano", "palakihin", "paliitin", "pakilakihin", "yung", "sa", "ng", "ko",
                        "video call", "Zoom", "Messenger", "Facebook", "FaceTime", "Viber", "GCash", "PhilHealth", "SSS",
                        "Pag-IBIG", "YouTube", "Shopee", "Lazada", "email", "i-email", "picture", "litrato", "Wi-Fi",
                        "printer", "OTP", "AnyDesk", "subtitles", "captions", "adobo", "sinigang"]

    /// Older users speak slowly and pause mid-sentence; 2.5 s of quiet means they're done.
    private func waitForPause() {
        pause?.invalidate()
        pause = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
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
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
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
