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
    /// Whisper is turning the recording into text (a second or two after they stop).
    @Published var transcribing = false
    /// Mic loudness 0…1 for the pulsing mic while listening.
    @Published var level: Float = 0
    private var vad: Timer?
    private var started = Date()
    /// Called with the transcript once the person pauses.
    var onFinished: ((String) -> Void)?
    private let engine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognizer: SFSpeechRecognizer?
    private var pause: Timer?
    /// Text from earlier segments: the recognizer ends a segment at every pause, older people pause mid-sentence.
    private var committed = ""
    /// The same speech as 16 kHz mono PCM for Whisper (memory only; written to a temp file just for transcription).
    private var recorder: PCMRecorder?

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
        let format = input.outputFormat(forBus: 0)
        let rec = PCMRecorder(from: format)
        recorder = rec
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            rec.append(buffer)   // audio thread; PCMRecorder is lock-protected
            DispatchQueue.main.async { self?.request?.append(buffer) }
        }
        engine.prepare()
        do { try engine.start() } catch { input.removeTap(onBus: 0); unavailable = true; return }
        text = ""
        committed = ""
        listening = true
        unavailable = false
        started = Date()
        if Whisper.available {
            // Whisper writes the words when they're done. Apple's live guesses at Taglish were so wrong that people
            // repeated themselves (and Whisper then wrote every repeat), so we don't show them.
            vad?.invalidate()
            vad = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self, self.listening, let a = self.recorder?.activity() else { return }
                    self.level = min(1, a.level * 8)
                    let elapsed = Date().timeIntervalSince(self.started)
                    // Done: ~2 s of quiet after they've said something, or 25 s in total; nothing said for 8 s: stop.
                    if (a.spoke && a.quietFor > 2.0) || elapsed > 25 || (!a.spoke && elapsed > 8) { self.finish() }
                }
            }
        } else {
            segment()
        }
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

    /// Older users speak slowly and pause mid-sentence; 3.5 s of quiet means they're done (or they tap the mic).
    private func waitForPause() {
        pause?.invalidate()
        pause = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { _ in
            DispatchQueue.main.async { self.finish() }
        }
    }

    func finish() {
        guard listening else { return }
        let said = text.trimmingCharacters(in: .whitespaces)
        let audio = recorder?.wav()
        stop()
        // Whisper (local, multilingual: understands Tagalog/Taglish) rewrites what Apple's live dictation heard.
        guard let audio, Whisper.available else { if !said.isEmpty { onFinished?(said) }; return }
        transcribing = true
        Task {
            let better = await Task.detached { Whisper.transcribe(wav: audio) }.value
            self.transcribing = false
            let final = (better?.isEmpty == false ? better! : said)
            if better != nil { self.text = final }
            if !final.isEmpty { self.onFinished?(final) }
        }
    }

    func stop() {
        pause?.invalidate()
        vad?.invalidate()
        level = 0
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


/// Keeps a 16 kHz mono 16-bit copy of the microphone for Whisper. Called on the audio thread.
final class PCMRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    /// Voice activity from the audio itself (Whisper mode has no live recognizer to say when speech stops).
    private(set) var spoke = false
    private(set) var lastLoud = Date()
    private(set) var level: Float = 0
    private let converter: AVAudioConverter?
    static let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!

    init(from input: AVAudioFormat) { converter = AVAudioConverter(from: input, to: Self.format) }

    func append(_ buffer: AVAudioPCMBuffer) {
        guard let converter else { return }
        let cap = AVAudioFrameCount(Double(buffer.frameLength) * 16000 / buffer.format.sampleRate + 32)
        guard let out = AVAudioPCMBuffer(pcmFormat: Self.format, frameCapacity: cap) else { return }
        var fed = false
        var err: NSError?
        converter.convert(to: out, error: &err) { _, status in
            if fed { status.pointee = .noDataNow; return nil }
            fed = true; status.pointee = .haveData; return buffer
        }
        guard err == nil, let ch = out.int16ChannelData, out.frameLength > 0 else { return }
        let n = Int(out.frameLength)
        var sum: Float = 0
        for i in 0..<n { let v = Float(ch[0][i]) / 32768; sum += v * v }
        let rms = (sum / Float(n)).squareRoot()
        lock.lock()
        data.append(Data(buffer: UnsafeBufferPointer(start: ch[0], count: n)))
        level = rms
        if rms > 0.02 { spoke = true; lastLoud = Date() }   // speech, not room noise
        lock.unlock()
    }

    /// A WAV file in the temp folder, or nil if there's under half a second of audio (Whisper invents words on silence).
    func activity() -> (spoke: Bool, quietFor: TimeInterval, level: Float) {
        lock.lock(); defer { lock.unlock() }
        return (spoke, Date().timeIntervalSince(lastLoud), level)
    }

    func wav() -> URL? {
        lock.lock(); let pcm = data; lock.unlock()
        guard pcm.count > 16000 else { return nil }
        var h = Data()
        func u32(_ v: UInt32) { var x = v.littleEndian; h.append(Data(bytes: &x, count: 4)) }
        func u16(_ v: UInt16) { var x = v.littleEndian; h.append(Data(bytes: &x, count: 2)) }
        h.append("RIFF".data(using: .ascii)!); u32(UInt32(36 + pcm.count)); h.append("WAVE".data(using: .ascii)!)
        h.append("fmt ".data(using: .ascii)!); u32(16); u16(1); u16(1); u32(16000); u32(32000); u16(2); u16(16)
        h.append("data".data(using: .ascii)!); u32(UInt32(pcm.count))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("gabay-voice.wav")
        try? (h + pcm).write(to: url)
        return url
    }
}

/// Local Whisper (whisper.cpp, large-v3-turbo q5_0): multilingual, so Taglish comes out right. Runs on this Mac's GPU
/// as a small server on 127.0.0.1 that Gabay starts itself, so the 574 MB model is loaded once, not per sentence.
enum Whisper {
    static let server = ["/opt/homebrew/bin/whisper-server", "/usr/local/bin/whisper-server"].first { FileManager.default.isExecutableFile(atPath: $0) }
    static let model = NSHomeDirectory() + "/Library/Application Support/Gabay/whisper/ggml-large-v3-turbo-q5_0.bin"
    static let url = URL(string: "http://127.0.0.1:8767/inference")!
    static var available: Bool { server != nil && FileManager.default.fileExists(atPath: model) }
    private static var process: Process?
    /// Biases spelling toward words people say to Gabay.
    static let prompt = "Gabay, anak, apo, Lola, video call, hindi daw ako nakikita, naririnig, paano, palakihin, paliitin, PhilHealth, GCash, SSS, Zoom, Messenger, FaceTime, YouTube, Wi-Fi, OTP, AnyDesk."

    /// Start the local server (short audio context + greedy decoding: ~2–3 s per sentence on an M4).
    static func start() {
        guard available, process == nil, let server else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: server)
        p.arguments = ["-m", model, "--host", "127.0.0.1", "--port", "8767", "-t", "6", "-l", "auto", "-ac", "768", "-bs", "1", "-bo", "1", "-nf"]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        if (try? p.run()) != nil { process = p }
    }

    static func stopServer() { process?.terminate(); process = nil }

    static func transcribe(wav: URL) -> String? {
        defer { try? FileManager.default.removeItem(at: wav) }
        guard let audio = try? Data(contentsOf: wav) else { return nil }
        let boundary = "gabay-\(UUID().uuidString)"
        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"voice.wav\"\r\nContent-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audio); body.append("\r\n".data(using: .utf8)!)
        field("response_format", "text")
        field("prompt", prompt)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 12   // never hold the person up; Apple's live text is the fallback
        let sem = DispatchSemaphore(value: 0)
        var result: String?
        URLSession.shared.uploadTask(with: req, from: body) { data, resp, _ in
            if (resp as? HTTPURLResponse)?.statusCode == 200, let data, var t = String(data: data, encoding: .utf8) {
                for junk in ["[BLANK_AUDIO]", "(silence)", "[ Silence ]", "[Music]", "(music)"] { t = t.replacingOccurrences(of: junk, with: "") }
                t = t.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
                result = t.isEmpty ? nil : t
            }
            sem.signal()
        }.resume()
        _ = sem.wait(timeout: .now() + 13)
        return result
    }
}
