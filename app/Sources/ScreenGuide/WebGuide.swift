import AppKit

/// Events from the extension (clicks, page changes, card buttons), queued for the web loop.
@MainActor
final class WebEvents {
    static let shared = WebEvents()
    private(set) var queue: [[String: Any]] = []
    func push(_ e: [String: Any]) { queue.append(e) }
    func drain() -> [[String: Any]] { defer { queue = [] }; return queue }
}

/// Websites: same brain and loop as native apps, but the page is read and drawn on by the
/// browser extension through `Bridge`. The extension makes no decisions.
extension GuideEngine {
    static func installBridgeEvents() {
        Bridge.shared.onEvent = { e in Task { @MainActor in WebEvents.shared.push(e) } }
    }

    func runWeb() async {
        let bridge = Bridge.shared
        _ = WebEvents.shared.drain()
        var clicked = Set<String>()
        overlay.hide()   // the card lives in the page
        while !Task.isCancelled, stepNo < 8 {
            bridge.send(["type": "status", "id": UUID().uuidString, "text": "Working out the next step…", "seconds": 0])
            guard let snap = await bridge.request(["type": "snapshot_request", "max_elements": 400]),
                  let elements = snap["elements"] as? [[String: Any]] else {
                log("WEB no snapshot"); webFail("I can't see this page.", "Click on the page once, then ask again."); return
            }
            let title = (snap["title"] as? String) ?? "this page"
            var refs: [String: String] = [:]
            var cands: [Candidate] = []
            for (i, e) in elements.enumerated() {
                guard let name = e["name"] as? String, !name.isEmpty, (e["enabled"] as? Bool) != false,
                      let ref = e["ref"] as? String else { continue }
                let c = Candidate(id: i, source: "web", role: e["role"] as? String ?? "button", label: name,
                                  context: e["context"] as? String ?? "", path: name, frame: nil, enabled: true)
                let k = Planner.key(c)
                if refs[k] == nil { refs[k] = ref; cands.append(c) }
            }
            let site = "web browser, on the website \"\(String(title.prefix(60)))\""
            let pick: Planner.Pick?
            do {
                pick = try await planner.choose(app: site, goal: goal, done: done, candidates: cands,
                                                instructions: "Which element on this page should the person use next?")
            } catch {
                log("WEB PLANNER ERROR \(error)"); webFail("I can't think right now.", "Make sure Gabay's helper is running, then try again."); return
            }
            guard let pick, let ref = refs[Planner.key(pick.candidate)] else { webFail("I couldn't find anything to click here.", ""); return }
            let key = Planner.key(pick.candidate)
            log("WEB STEP \(stepNo + 1) pick=\(key) conf=\(String(format: "%.2f", pick.confidence))")
            // Re-picking something already clicked means the goal is reached.
            if clicked.contains(key) { webFinish(); return }
            stepNo += 1

            var msg: [String: Any] = ["type": "highlight", "ref": ref, "step": stepNo]
            if pick.confidence < 0.3, let alt = pick.runnersUp.first.flatMap({ refs[Planner.key($0)] }) {
                msg["candidates"] = [ref, alt]
                msg["instruction"] = "I think it's one of these two."
                msg["hint"] = "Just click the one you think is right."
                speakText("I think it's one of these two. Just click the one you think is right.")
            } else {
                let (text, hint) = webPhrase(pick.candidate)
                msg["instruction"] = text
                msg["hint"] = hint
                speakText(plain(text) + " " + hint)
            }
            _ = await bridge.request(msg)

            // Wait for the person: a click on the target, a submit, or the page changing.
            var advanced = false
            while !Task.isCancelled, !advanced {
                try? await Task.sleep(nanoseconds: 200_000_000)
                for e in WebEvents.shared.drain() {
                    switch e["type"] as? String {
                    case "user_action":
                        let kind = e["kind"] as? String ?? ""
                        if (e["on_target"] as? Bool) == true || kind == "submit" { advanced = true }
                    case "page_changed": advanced = true
                    case "card_button":
                        switch e["button"] as? String {
                        case "stop": stop(); return
                        case "again", "read_aloud": speakText(plain(msg["instruction"] as? String ?? "") + " " + (msg["hint"] as? String ?? ""))
                        case "stuck":
                            var m = msg; m["style"] = "spotlight"
                            _ = await bridge.request(m)
                        default: break
                        }
                    default: break
                    }
                }
            }
            if Task.isCancelled { return }
            clicked.insert(key)
            done.append("clicked \(key)")
            bridge.send(["type": "status", "id": UUID().uuidString, "text": "That's right.", "seconds": 1])
            try? await Task.sleep(nanoseconds: 700_000_000)
            if ["Sign in", "Log in", "Login", "Submit", "Send", "Pay", "Search", "Save"].contains(pick.candidate.label) && stepNo >= 2 {
                webFinish(); return
            }
        }
        if !Task.isCancelled { webFinish() }
    }

    private func webPhrase(_ c: Candidate) -> (String, String) {
        switch c.role {
        case "textbox", "searchbox", "combobox":
            return ("Click in the **\(c.label)** box and type what you need.", "Press Enter when you're done.")
        case "checkbox", "switch", "radio": return ("Click **\(c.label)**.", "")
        case "link": return ("Click **\(c.label)**.", c.context.isEmpty ? "" : "It's in the \(c.context) part of the page.")
        default: return ("Click **\(c.label)**.", "")
        }
    }

    private func webFinish() {
        log("WEB DONE steps=\(done)")
        Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
        Bridge.shared.send(["type": "status", "id": UUID().uuidString, "text": "All done. You did it.", "seconds": 5])
        finish()
    }

    private func webFail(_ text: String, _ hint: String) {
        Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
        show(.done, label: "Hmm", text: text, hint: hint, target: nil)
    }
}
