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

    /// Point at the site's open tab if there is one; otherwise at the address bar, with what to type.
    /// Gabay never types or clicks: the person does.
    func goToSite(_ sc: SiteCheck) async -> Bool {
        guard let browser = Self.frontRegularApp() else { return false }
        let state = await Task.detached { ScreenReader.state(of: browser, maxPerWindow: 600) }.value
        let name = sc.siteName.lowercased()
        let tabs = state.candidates.filter { $0.source == "window" && !name.isEmpty && $0.label.lowercased().hasPrefix(name)
                                             && ["tab", "row", "button", "option"].contains($0.role) }
        if let tab = tabs.first {
            stepNo += 1
            let ok = await guide(Planner.Pick(candidate: Candidate(id: tab.id, source: tab.source, role: tab.role, label: tab.label,
                                                                   context: "your open tabs", path: tab.path, frame: tab.frame, enabled: true),
                                              confidence: 0.9, runnersUp: []))
            if Task.isCancelled { return false }
            overlay.hide()   // web steps draw in the page
            if ok { return true }
            notThis = false   // "Not this one" on the tab: fall back to typing the address
        }
        let bar = state.candidates.first { $0.source == "window" && ["text field", "combo box", "search field"].contains($0.role)
            && Self.looksLikeAddressBar($0.label) }
        stepNo += 1
        show(.guiding, label: "Step \(stepNo)", text: "Type **\(sc.address)** here, then press **Return**.",
             hint: "This opens \(sc.siteName).", target: bar?.frame.map { CGRect(x: $0[0], y: $0[1], width: $0[2], height: $0[3]) })
        _ = ClickWatcher.shared.drain()
        notThis = false
        let site = sc.address.replacingOccurrences(of: "www.", with: "")
        waiting: while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if notThis { notThis = false; break waiting }   // nothing else to offer here; re-read the page
            if ClickWatcher.shared.drain().contains(where: { if case .enter = $0 { return true }; return false }) { break }
            // They may switch tabs or follow a link instead of typing: arriving on the site counts.
            for e in WebEvents.shared.drain() {
                if (e["type"] as? String) == "card_button", (e["button"] as? String) == "stop" { stop(); return false }
                if (e["type"] as? String) == "page_changed", let u = e["url"] as? String, (URL(string: u)?.host ?? "").contains(site) { break waiting }
            }
        }
        if Task.isCancelled { return false }
        overlay.hide()
        return true
    }

    /// A page change that's a real navigation (new URL), not just a big DOM update on the same page.
    func moved(_ e: [String: Any], from url: String) -> Bool {
        guard (e["type"] as? String) == "page_changed" else { return false }
        if (e["reason"] as? String) != "dom_mutation" { return true }
        return (e["url"] as? String).map { $0 != url } ?? false
    }

    static func looksLikeAddressBar(_ label: String) -> Bool {
        let l = label.lowercased()
        return ["address", "search or", "url", "enter"].contains { l.contains($0) }
    }

    func runWeb() async {
        let bridge = Bridge.shared
        _ = WebEvents.shared.drain()
        var clicked = Set<String>()
        var parts: [String]? = nil
        var partIndex = 0
        overlay.hide()   // the card lives in the page
        while !Task.isCancelled, stepNo < 8 {
            bridge.send(["type": "status", "id": UUID().uuidString, "text": "Working out the next step…", "seconds": 0])
            guard let snap = await bridge.request(["type": "snapshot_request", "max_elements": 400]),
                  let elements = snap["elements"] as? [[String: Any]] else {
                log("WEB no snapshot"); webFail("I can't see this page.", "Click on the page once, then ask again."); return
            }
            let title = (snap["title"] as? String) ?? "this page"
            let url = (snap["url"] as? String) ?? ""
            // First step: make sure we're on the right website before guessing at this page.
            let sc0 = stepNo == 0 && done.isEmpty ? await SiteRoute.check(goal: goal, title: title, url: url) : nil
            if stepNo == 0 { log("WEB SITECHECK page=\(URL(string: url)?.host ?? "?") -> \(sc0.map { "\($0.onThisPage) \($0.siteName) \($0.address)" } ?? "nil")") }
            if let sc = sc0, !sc.onThisPage,
               !sc.address.isEmpty, !(URL(string: url)?.host ?? "").contains(sc.address.replacingOccurrences(of: "www.", with: "")) {
                log("WEB SITE \(sc.siteName) \(sc.address) (page: \(URL(string: url)?.host ?? "?"))")
                Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
                if await goToSite(sc) { done.append("opened \(sc.siteName)"); try? await Task.sleep(nanoseconds: 1_500_000_000); continue }
                return
            }
            if parts == nil {
                parts = await WebPlan.parts(for: goal, site: title)
                log("WEB PARTS \(parts ?? [])")
            }
            var refs: [String: String] = [:]
            var cands: [Candidate] = []
            for (i, e) in elements.enumerated() {
                guard let name = e["name"] as? String, !name.isEmpty, (e["enabled"] as? Bool) != false,
                      let ref = e["ref"] as? String else { continue }
                let c = Candidate(id: i, source: "web", role: e["role"] as? String ?? "button", label: name,
                                  context: e["context"] as? String ?? "", path: name, frame: nil, enabled: true)
                let k = Planner.key(c)
                if refs[k] == nil, !clicked.contains(k), !rejected.contains(k) { refs[k] = ref; cands.append(c) }
            }
            let site = "web browser, on the website \"\(String(title.prefix(60)))\""
            var pick: Planner.Pick?
            do {
                // One part at a time; a weak best guess on a part usually means it's done: try the next part.
                while true {
                    let part = (parts ?? []).indices.contains(partIndex) ? parts![partIndex] : goal
                    pick = try await planner.choose(app: site, goal: part, done: done, candidates: cands,
                                                    instructions: "Which element on this page should the person use next?")
                    log("WEB PART \(partIndex + 1) \"\(part)\" -> \(pick.map { "\(Planner.key($0.candidate)) \(String(format: "%.2f", $0.confidence))" } ?? "-")")
                    if let p = pick, p.confidence < 0.2, partIndex + 1 < (parts ?? []).count { partIndex += 1; continue }
                    break
                }
            } catch {
                log("WEB PLANNER ERROR \(error)"); webFail("I can't think right now.", "Make sure Gabay's helper is running, then try again."); return
            }
            guard let pick, let ref = refs[Planner.key(pick.candidate)] else { webFail("I couldn't find anything to click here.", ""); return }
            let pickPart = partIndex   // the part this step serves (page changes may move partIndex while waiting)
            let key = Planner.key(pick.candidate)
            if let w = ScamGuard.check(label: pick.candidate.label) {
                log("WEB SCAM GUARD \(pick.candidate.label)")
                Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
                show(.detour, label: "Wait", text: w.text, hint: w.hint, target: nil)
                speakText(w.text)
                return
            }
            log("WEB STEP \(stepNo + 1) pick=\(key) conf=\(String(format: "%.2f", pick.confidence))")
            if stepNo == 0, rejected.isEmpty, pick.confidence < 0.3 {
                webFail("I can't find that on this page.", "Go to the website you need first, or say it another way."); return
            }
            // After the first steps, a weak best guess often means the goal is reached: ask, never assume.
            if stepNo >= 1, pick.confidence < 0.2, !keepGoing {
                log("WEB weak next step (\(String(format: "%.2f", pick.confidence))) -> ask")
                Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
                guard let yes = await askYesNo("Did that do it?", yes: "Yes, all done", no: "Not yet") else { return }
                if yes { webFinish(); return }
                overlay.hide()
                keepGoing = true
                continue   // fresh snapshot: refs from before their pause may be stale
            }
            // The page moved on while we were thinking (they pressed Enter, a link loaded): re-read it, don't point at stale things.
            let early = WebEvents.shared.drain()
            if early.contains(where: { ($0["type"] as? String) == "card_button" && ($0["button"] as? String) == "stop" }) {
                Bridge.shared.send(["type": "clear", "id": UUID().uuidString]); stop(); return
            }
            if early.contains(where: { moved($0, from: url) }) {
                log("WEB page changed while thinking -> re-read")
                continue
            }
            for e in early { WebEvents.shared.push(e) }
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
                msg["hint"] = [hint, "This gets you closer to: \(goal)."].filter { !$0.isEmpty }.joined(separator: " ")
                speakText(plain(text) + " " + hint)
            }
            bridge.send(["type": "status", "id": UUID().uuidString, "text": "", "seconds": 0])   // drop "Working out…"
            let hl = await bridge.request(msg)
            log("WEB highlight -> \(hl?["type"] as? String ?? "no reply") \(hl?["reason"] as? String ?? "")")

            // Wait for the person: a click on the target, a submit, or the page changing.
            var advanced = false
            var partMoved = false   // one part per step: sites fire several page_changed events for one navigation
            let typing = ["textbox", "searchbox", "combobox"].contains(pick.candidate.role)
            _ = ClickWatcher.shared.drain()
            notThis = false
            while !Task.isCancelled, !advanced, !notThis {
                try? await Task.sleep(nanoseconds: 200_000_000)
                // Many sites (YouTube) search on Enter without a form submit; the page change follows, but Enter is enough.
                if typing, ClickWatcher.shared.drain().contains(where: { if case .enter = $0 { return true }; return false }) {
                    advanced = true
                    try? await Task.sleep(nanoseconds: 800_000_000)   // let the results page load before re-reading
                }
                for e in WebEvents.shared.drain() {
                    switch e["type"] as? String {
                    case "user_action":
                        let kind = e["kind"] as? String ?? ""
                        // A box isn't done when they click into it, only when they send what they typed.
                        if kind == "submit" || (!typing && (e["on_target"] as? Bool) == true) { advanced = true }
                    case "page_changed":
                        advanced = true
                        // A real navigation usually means this part is done (search submitted, video opened);
                        // a big DOM update on the same page (menus, players) doesn't.
                        if moved(e, from: url), !partMoved, partIndex + 1 < (parts ?? []).count { partIndex += 1; partMoved = true }
                    case "card_button":
                        switch e["button"] as? String {
                        case "stop": stop(); return
                        case "not_this":
                            // One-click recovery: drop this guess, ask the model for its next best.
                            rejected.insert(key); stepNo -= 1; notThis = true
                            log("WEB NOT THIS \(key)")
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
            if notThis { notThis = false; continue }
            clicked.insert(key)
            done.append("clicked \(key)")
            bridge.send(["type": "status", "id": UUID().uuidString, "text": "That's right.", "seconds": 1])
            try? await Task.sleep(nanoseconds: 700_000_000)
            keepGoing = false
            let lastPart = pickPart + 1 >= (parts ?? []).count
            if lastPart, ["Sign in", "Log in", "Login", "Submit", "Send", "Pay", "Search", "Save"].contains(pick.candidate.label) && stepNo >= 2 {
                Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
                guard let yes = await askYesNo("Did that do it?", yes: "Yes, all done", no: "Not yet") else { return }
                if yes { webFinish(); return }
                overlay.hide()
                keepGoing = true
            }
        }
        // Out of steps is not "done": ask, and end honestly if it isn't.
        if !Task.isCancelled {
            Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
            guard let yes = await askYesNo("Did that do it?", yes: "Yes, all done", no: "Not yet") else { return }
            if yes { webFinish() } else { webFail("I'm not sure what's next.", "Ask me again with a bit more detail.") }
        }
    }

    private func webPhrase(_ c: Candidate) -> (String, String) {
        switch c.role {
        case "textbox", "searchbox", "combobox":
            return ("Click in the **\(c.label)** box and type what you're looking for.", "Then press **Enter**.")
        case "checkbox", "switch", "radio": return ("Click **\(c.label)**.", "")
        case "link": return ("Click **\(c.label)**.", c.context.isEmpty ? "" : "It's in the \(c.context) part of the page.")
        default: return ("Click **\(c.label)**.", "")
        }
    }

    private func webFinish() {
        log("WEB DONE steps=\(done)")
        Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
        finish()
    }

    private func webFail(_ text: String, _ hint: String) {
        Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
        show(.done, label: "Hmm", text: text, hint: hint, target: nil)
    }
}
