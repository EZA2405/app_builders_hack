import Foundation
import Network

/// WebSocket bridge to the Gabay browser extension (extension/SPEC.md) on ws://127.0.0.1:47823/ext.
/// The extension is only eyes and hands in the page (snapshot, ring + card, clicks); every decision
/// is made here, by the local model.
final class Bridge: @unchecked Sendable {
    static let shared = Bridge()
    /// Only our extension may connect: any web page can try to open ws://127.0.0.1.
    static let allowedOrigin = "chrome-extension://iokhdpnepbjnngdafdfafcjlpdbnolio"

    private var listener: NWListener?
    private var conn: NWConnection?
    private let queue = DispatchQueue(label: "gabay.bridge")
    private var pending: [String: CheckedContinuation<[String: Any], Never>] = [:]
    /// Events the guide loop waits on (user_action, page_changed, card_button).
    var onEvent: (@Sendable ([String: Any]) -> Void)?
    private(set) var connected = false

    func start() {
        let ws = NWProtocolWebSocket.Options()
        ws.autoReplyPing = true
        ws.setClientRequestHandler(queue) { _, headers in
            let origin = headers.first { $0.name.lowercased() == "origin" }?.value
            return NWProtocolWebSocket.Response(status: origin == Bridge.allowedOrigin ? .accept : .reject,
                                                subprotocol: nil, additionalHeaders: nil)
        }
        let params = NWParameters.tcp
        params.defaultProtocolStack.applicationProtocols.insert(ws, at: 0)
        params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: 47823)
        params.allowLocalEndpointReuse = true
        do { listener = try NWListener(using: params) } catch { NSLog("Gabay bridge: \(error)"); return }
        listener?.newConnectionHandler = { [weak self] c in self?.accept(c) }
        listener?.start(queue: queue)
    }

    private func accept(_ c: NWConnection) {
        conn?.cancel()
        conn = c
        c.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready: self?.connected = true
            case .failed, .cancelled: if self?.conn === c { self?.connected = false }
            default: break
            }
        }
        c.start(queue: queue)
        receive(c)
    }

    private func receive(_ c: NWConnection) {
        c.receiveMessage { [weak self] data, _, _, error in
            guard let self, error == nil else { return }
            if let data, let msg = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.handle(msg)
            }
            self.receive(c)
        }
    }

    private func handle(_ msg: [String: Any]) {
        let type = msg["type"] as? String ?? ""
        if let id = msg["id"] as? String, let k = pending.removeValue(forKey: id),
           ["snapshot", "highlight_ok", "highlight_error"].contains(type) {
            k.resume(returning: msg)
            return
        }
        if type == "hello" { connected = true }
        if ["user_action", "page_changed", "card_button"].contains(type) { onEvent?(msg) }
    }

    func send(_ msg: [String: Any]) {
        guard let conn, let data = try? JSONSerialization.data(withJSONObject: msg) else { return }
        let meta = NWProtocolWebSocket.Metadata(opcode: .text)
        conn.send(content: data, contentContext: NWConnection.ContentContext(identifier: "msg", metadata: [meta]),
                  isComplete: true, completion: .contentProcessed { _ in })
    }

    /// Send a request and wait for the reply with the same id (or nil after `timeout`).
    func request(_ msg: [String: Any], timeout: Double = 8) async -> [String: Any]? {
        let id = UUID().uuidString
        var m = msg; m["id"] = id
        return await withCheckedContinuation { (k: CheckedContinuation<[String: Any], Never>) in
            queue.async {
                self.pending[id] = k
                self.send(m)
                self.queue.asyncAfter(deadline: .now() + timeout) {
                    if let k = self.pending.removeValue(forKey: id) { k.resume(returning: ["type": "timeout"]) }
                }
            }
        }.nilIfTimeout
    }
}

private extension Dictionary where Key == String, Value == Any {
    var nilIfTimeout: [String: Any]? { (self["type"] as? String) == "timeout" ? nil : self }
}
