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

    static let actionWords = ["like", "love", "react", "share", "comment", "follow", "unfollow", "add friend", "confirm",
                              "accept", "decline", "block", "report", "post", "send", "delete", "remove", "unfriend",
                              "subscribe", "join", "buy", "pay", "checkout", "place order", "donate"]
    static func socialAction(_ name: String) -> Bool {
        let n = name.lowercased()
        return actionWords.contains { w in n == w || n.hasPrefix(w + " ") || n.hasPrefix(w + ":") }
    }
    static func asksFor(_ name: String, in goal: String) -> Bool {
        let n = name.lowercased(), g = goal.lowercased()
        return actionWords.contains { n.hasPrefix($0) && g.contains($0) }
    }

    /// Does the page title name the subject of the request? ("read about José Rizal" vs "José Rizal - Wikipedia").
    /// Accent-insensitive; a word counts if one contains the other (dictation spells names oddly: "Oserizal").
    static func titleMatches(goal: String, title: String) -> Bool {
        func words(_ s: String) -> [String] {
            s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
                .split(whereSeparator: { !$0.isLetter }).map(String.init).filter { $0.count >= 4 }
        }
        let stop: Set<String> = ["want", "read", "about", "watch", "find", "look", "show", "open", "paano", "gusto", "with", "this",
                                 "that", "page", "website", "please", "help", "where", "what", "video", "videos", "search", "home",
                                 "wikipedia", "youtube", "google", "turn", "words", "bottom", "make", "into", "from", "your", "mine"]
        let g = words(goal).filter { !stop.contains($0) }
        let t = Set(words(title).filter { !stop.contains($0) })
        return g.contains { gw in t.contains { tw in gw.contains(tw) || tw.contains(gw) } }
    }

    /// A page change that's a real navigation (new URL), not just a big DOM update on the same page.
    func moved(_ e: [String: Any], from url: String) -> Bool {
        guard (e["type"] as? String) == "page_changed", (e["reason"] as? String) != "tab_switch" else { return false }
        // Same address = same page, whatever the reason (SPA feeds re-render all the time).
        if let u = e["url"] as? String, !u.isEmpty { return u != url }
        return (e["reason"] as? String) == "navigation"
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
        var lastHost = ""          // the site this session is on
        var expectNav = true       // the last step could have moved the page (so a new site is expected)
        overlay.hide()   // the card lives in the page
        while !Task.isCancelled, stepNo < 8 {
            bridge.send(["type": "status", "id": UUID().uuidString, "text": "Working out the next step…", "seconds": 0])
            // 150 elements, visible ones first (the extension sorts them): 3x fewer model calls than 400, much faster.
            // A page that's still loading (they clicked a link) can't answer yet: try again for a few seconds.
            var snapshot: [String: Any]?
            for attempt in 0..<9 {
                snapshot = await bridge.request(["type": "snapshot_request", "max_elements": 150])
                // Still loading (a link was just clicked): an empty or nearly empty page isn't the real page yet.
                let named = (snapshot?["elements"] as? [[String: Any]])?.filter { !(($0["name"] as? String) ?? "").isEmpty }.count ?? 0
                if named >= 5 || (attempt >= 4 && snapshot?["elements"] is [[String: Any]]) { break }
                if Task.isCancelled { return }
                log("WEB snapshot retry \(attempt + 1)")
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
            guard let snap = snapshot, let elements = snap["elements"] as? [[String: Any]] else {
                log("WEB no snapshot"); webFail("I can't see this page.", "Click on the page once, then ask again."); return
            }
            let title = (snap["title"] as? String) ?? "this page"
            let url = (snap["url"] as? String) ?? ""
            let host = URL(string: url)?.host ?? ""
            // A different site without any step that could have taken them there = they switched tabs. That's a new
            // context: stop instead of applying the old request to an unrelated page.
            if !lastHost.isEmpty, host != lastHost, !expectNav {
                log("WEB switched site \(lastHost) -> \(host)")
                Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
                show(.done, label: "Stopped", text: "You switched to another page.", hint: "Ask me again there if you need help.", target: nil)
                return
            }
            lastHost = host
            let navigated = expectNav
            expectNav = false
            // Arrived: after their step, a page whose title names what they asked for ("José Rizal - Wikipedia") may be
            // the end. Only on the last part (a YouTube results page also names the search, but captions are still to do).
            let onLastPart = (parts ?? []).isEmpty || partIndex + 1 >= (parts ?? []).count
            if navigated, stepNo >= 1, onLastPart, !keepGoing, Self.titleMatches(goal: originalWebGoal ?? goal, title: title) {
                log("WEB title matches goal: \(title)")
                Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
                guard let yes = await askYesNo("Is this what you wanted?", yes: "Yes, this is it", no: "Not yet") else { return }
                if yes { webFinish(); return }
                overlay.hide()
                keepGoing = true
            }
            // First step: make sure we're on the right website before guessing at this page.
            let sc0 = stepNo == 0 && done.isEmpty ? await SiteRoute.check(goal: goal, title: title, url: url) : nil
            if stepNo == 0 { log("WEB SITECHECK page=\(URL(string: url)?.host ?? "?") -> \(sc0.map { "\($0.onThisPage) \($0.siteName) \($0.address)" } ?? "nil")") }
            if let sc = sc0, !sc.onThisPage,
               !sc.address.isEmpty, !(URL(string: url)?.host ?? "").contains(sc.address.replacingOccurrences(of: "www.", with: "")) {
                log("WEB SITE \(sc.siteName) \(sc.address) (page: \(URL(string: url)?.host ?? "?"))")
                Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
                if await goToSite(sc) { done.append("opened \(sc.siteName)"); expectNav = true; lastHost = ""; try? await Task.sleep(nanoseconds: 1_500_000_000); continue }
                return
            }
            // Split only when they actually asked for two things ("…and turn on subtitles", "tapos…"); otherwise the
            // request stays whole (splitting "see my friend requests" into fake clicks sent it to "Your profile").
            let g0 = " " + goal.lowercased() + " "
            let twoThings = [" and ", " then ", " tapos ", " pagkatapos ", " at saka ", " also "].contains { g0.contains($0) }
            if parts == nil, !twoThings { parts = []; log("WEB PARTS [] (one thing)") }
            if parts == nil {
                let p = await WebPlan.parts(for: goal, site: title)
                // One thing ("read about José Rizal") stays one goal; splitting it into clicks confused the picker.
                parts = p.count >= 2 ? p : []
                log("WEB PARTS \(parts ?? [])")
            }
            var refs: [String: String] = [:]
            var rects: [String: CGRect] = [:]
            var cands: [Candidate] = []
            let vp = (snap["viewport"] as? [Double]) ?? []
            let page = vp.count == 2 ? CGRect(x: 0, y: 0, width: vp[0], height: vp[1]) : .zero
            for (i, e) in elements.enumerated() {
                guard let name = e["name"] as? String, !name.isEmpty, (e["enabled"] as? Bool) != false,
                      let ref = e["ref"] as? String else { continue }
                let c = Candidate(id: i, source: "web", role: e["role"] as? String ?? "button", label: name,
                                  context: e["context"] as? String ?? "", path: name, frame: nil, enabled: true)
                let k = Planner.key(c)
                // Never point at actions that do something to other people or can't be taken back (Like, Share,
                // Delete…) unless the request asks for that action.
                if Self.socialAction(name), !Self.asksFor(name, in: goal) { continue }
                if refs[k] == nil, !clicked.contains(k), !rejected.contains(k) {
                    refs[k] = ref; cands.append(c)
                    if let r = e["rect"] as? [Double], r.count == 4 { rects[k] = CGRect(x: r[0], y: r[1], width: r[2], height: r[3]) }
                }
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
            if early.contains(where: { ($0["reason"] as? String) == "tab_switch" }) {
                log("WEB tab switched (while thinking)")
                Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
                show(.done, label: "Stopped", text: "You switched to another tab.", hint: "Ask me again there if you need help.", target: nil)
                return
            }
            if early.contains(where: { moved($0, from: url) }) {
                // They finished this part themselves (pressed Enter, a result loaded): move to the next part too.
                if partIndex + 1 < (parts ?? []).count, stepNo > 0 { partIndex += 1; log("WEB part \(partIndex + 1) (page moved on)") }
                log("WEB page changed while thinking -> re-read")
                expectNav = true
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
                // Laya picked the element; Apple's on-device model words it (varied, checked), else a clean template.
                let label = Phrasing.clean(pick.candidate.label)
                let pos = rects[key].map { Phrasing.position($0, in: page, noun: "page") } ?? ""
                let fallback = webPhrase(pick.candidate, label: label, position: pos)
                let (text, hint) = await StepVoice.line(goal: goal, place: String(title.prefix(60)), step: stepNo, label: label,
                                                        role: pick.candidate.role, position: pos) ?? fallback
                msg["instruction"] = text
                msg["hint"] = hint
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
                    case "page_changed" where (e["reason"] as? String) == "tab_switch":
                        log("WEB tab switched")
                        Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
                        show(.done, label: "Stopped", text: "You switched to another tab.", hint: "Ask me again there if you need help.", target: nil)
                        return
                    case "page_changed":
                        // Only a real navigation (new address) is progress. Feeds (Facebook, YouTube) change the page
                        // constantly; counting that as "they did the step" raced through 7 steps in 30 s.
                        guard moved(e, from: url) else { break }
                        advanced = true
                        if !partMoved, partIndex + 1 < (parts ?? []).count { partIndex += 1; partMoved = true }
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
            expectNav = true   // this step was theirs: the next page may be on another site
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

    private func webPhrase(_ c: Candidate, label: String, position: String) -> (String, String) {
        let where_ = position.isEmpty ? "" : "It's \(position)."
        switch c.role {
        case "textbox", "searchbox", "combobox":
            return ("Click the **\(label)** box and type what you're looking for.", "Then press **Enter**.")
        case "tab": return ("Click the **\(label)** tab.", where_)
        case "checkbox", "switch", "radio": return ("Click **\(label)**.", where_)
        default: return ("Click **\(label)**.", where_)
        }
    }

    private func webFinish() {
        log("WEB DONE steps=\(done)")
        Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
        finish()
    }

    private func webFail(_ text: String, _ hint: String) {
        Bridge.shared.send(["type": "clear", "id": UUID().uuidString])
        Bridge.shared.send(["type": "status", "id": UUID().uuidString, "text": "", "seconds": 0])
        show(.done, label: "Hmm", text: text, hint: hint, target: nil)
    }
}
