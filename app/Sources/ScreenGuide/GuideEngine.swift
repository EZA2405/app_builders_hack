import AppKit
import AVFoundation
import ApplicationServices

/// The step loop: read screen → local model picks the next control → ring + card →
/// wait for the user's own click → confirm → repeat. Gabay never clicks for the user.
@MainActor
final class GuideEngine {
    let overlay = OverlayController()
    var planner = Planner()
    var readAloud: Bool { Prefs.shared.readAloud }
    private let speech = AVSpeechSynthesizer()
    private var app: NSRunningApplication?
    var goal = ""
    var done: [String] = []
    var stepNo = 0
    var task: Task<Void, Never>?
    private var doneTyping = false
    /// "Not this one": guesses the person rejected this task; the model never offers them again.
    var rejected = Set<String>()
    /// Apple model's verdict for this goal: nil = not asked yet, "" = not a settings job, else the pane.
    var settingsPane: String?
    /// Apple model's route for this goal (on-screen names, in order); nil = not planned yet.
    var waypoints: [String]?
    private var movedOn = false
    private var lastState: ScreenState?
    /// Troubleshooting: the checklist (made once per request) and where we are in it.
    var fixes: [Fix] = []
    var fixIndex = 0
    var originalGoal = ""
    private var alreadyFine = false
    /// Apple's on-device model's one-line plan for this task, shown on the first card.
    var planLine: String?
    /// Set when Gabay points at a Dock icon: the app we expect the person to open next.
    var expectedApp: String?
    var notThis = false

    init() {
        overlay.onStop = { [weak self] in self?.userStop() }
        overlay.onAgain = { [weak self] in self?.speak() }
        overlay.onStuck = { [weak self] in self?.stuck() }
        overlay.onDone = { [weak self] in self?.markDoneTyping() }
        overlay.onNotThis = { [weak self] in self?.notThis = true }
        overlay.onStillBroken = { [weak self] in
            guard let self else { return }
            self.overlay.model.askWorked = false
            if !self.fixes.isEmpty { self.nextFix(); return }
            // No checklist to fall back on: ask what happens now, so the next request carries what we learned.
            self.stop()
            NotificationCenter.default.post(name: .gabayAskAgain, object: nil)
        }
        ClickWatcher.shared.start()
    }

    func start(goal: String, app: NSRunningApplication) {
        stop()
        self.goal = goal; self.app = app; done = []; stepNo = 0; rejected = []; notThis = false; planLine = nil; settingsPane = nil; waypoints = nil
        log("START goal=\(goal) app=\(app.localizedName ?? "?")")
        if let w = ScamGuard.check(goal: goal) {
            log("SCAM GUARD goal")
            show(.detour, label: "Wait", text: w.text, hint: w.hint, target: nil)
            return
        }
        app.activate()
        let web = BrowserGuide.browsers.contains(app.bundleIdentifier ?? "") && Bridge.shared.connected
        task = Task {
            // The local model also checks the goal (catches rewordings the keyword rules miss).
            let p = await self.planner.risky(goal: goal)
            self.log("RISK p=\(String(format: "%.2f", p))")
            if p >= 0.6 {
                self.show(.detour, label: "Wait", text: "Wait. Real banks and government offices never ask you to share your screen or install apps like this.",
                          hint: "If someone asked you to do this, stop and call your family first.", target: nil)
                return
            }
            if !web {
                self.originalGoal = goal
                // Off by default: measured unreliable (missed camera problems, gave camera fixes for "no sound").
                self.fixes = ProcessInfo.processInfo.environment["GABAY_TROUBLESHOOT"] == "1" ? await Troubleshooter.fixes(for: goal) : []
                self.fixIndex = 0
                self.log("FIXES \(self.fixes.map(\.task))")
                if let f = self.fixes.first { self.beginFix(f) }
            }
            if web { await self.runWeb() } else { await self.run() }
        }
    }

    /// Stop pressed on the card: say plainly that nothing changed, then get out of the way.
    func userStop() {
        let m = overlay.model
        if m.mode == .done || m.label == "Wait" || m.mode == .hidden { stop(); return }
        task?.cancel(); task = nil
        speech.stopSpeaking(at: .immediate)
        show(.done, label: "Stopped", text: "Okay, I stopped. Nothing was changed.", hint: "", target: nil)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if self.overlay.model.label == "Stopped" { self.overlay.hide() }
        }
    }

    func stop() {
        task?.cancel(); task = nil
        speech.stopSpeaking(at: .immediate)
        overlay.hide()
    }

    // MARK: - Loop

    private func run() async {
        guard let first = app else { return }
        // Without Accessibility the screen reads as empty and the loop would find nothing, silently.
        guard AXIsProcessTrusted() else {
            log("NO ACCESSIBILITY")
            show(.done, label: "One more thing", text: "Gabay needs permission to see your screen.",
                 hint: "Open System Settings › Privacy & Security › Accessibility and turn on Gabay. Then ask again.", target: nil)
            return
        }
        var app = first
        while !Task.isCancelled, stepNo < 8 {
            // Follow the person only into the app Gabay sent them to (a Dock step). Anywhere else, wait.
            if let front = Self.frontRegularApp(), front != app {
                if let expected = expectedApp, front.localizedName == expected {
                    log("APP \(expected)")
                    app = front; self.app = front; expectedApp = nil
                } else {
                    let name = app.localizedName ?? "your app"
                    show(.detour, label: "Paused", text: "I'll wait. Go back to **\(name)** when you're ready.",
                         hint: "Nothing has been changed.", target: nil)
                    while !Task.isCancelled, Self.frontRegularApp() != app { try? await Task.sleep(nanoseconds: 400_000_000) }
                    continue
                }
            }
            show(.thinking, label: "Got it", text: "Looking…", hint: "", target: nil)
            let state = await read(app)
            lastState = state
            let pick: Planner.Pick?
            do {
                pick = try await decide(state, app: app)
            } catch {
                log("PLANNER ERROR \(error)")
                show(.done, label: "Something went wrong", text: "I can't think right now.", hint: "Make sure Gabay's helper is running, then try again.", target: nil)
                return
            }
            guard let pick else {
                log("NO CANDIDATES app=\(app.localizedName ?? "?")")
                show(.done, label: "Hmm", text: "I can't see that on this screen. Can you say it another way?",
                     hint: "Or open the app you want help with first, then ask again.", target: nil)
                return
            }
            // Menus have no "one of these two" view; a near-guess menu step sends people somewhere wrong.
            if !done.isEmpty, pick.confidence < 0.3 { finish(); return }   // real progress, nothing sensible left: done
            if pick.candidate.source == "menu", pick.confidence < 0.3 {
                log("UNSURE pick=\(Planner.key(pick.candidate)) conf=\(String(format: "%.2f", pick.confidence))")
                show(.done, label: "I'm not sure", text: "I can't see that on this screen. Can you say it another way?",
                     hint: "For a photo, open the photo first, then ask again.", target: nil)
                return
            }
            if let w = ScamGuard.check(label: pick.candidate.label) {
                log("SCAM GUARD step \(pick.candidate.label)")
                show(.detour, label: "Wait", text: w.text, hint: w.hint, target: pick.candidate.frame.map(rect))
                return
            }
            if stepNo == 0, PlanVoice.isEnglish(goal), let line = await PlanVoice.plan(goal: goal, route: pick.candidate.source == "menu" ? pick.candidate.path : pick.candidate.label) {
                planLine = line
                log("PLAN \(line)")
            }
            log("STEP \(stepNo + 1) pick=\(Planner.key(pick.candidate)) conf=\(String(format: "%.2f", pick.confidence))")
            stepNo += 1
            let ok = await guide(pick)
            if notThis {
                // Recovery is one click: drop this guess and ask the model for its next best.
                notThis = false
                rejected.insert(Planner.key(pick.candidate))
                stepNo -= 1
                log("NOT THIS \(Planner.key(pick.candidate))")
                show(.thinking, label: "Okay", text: "Looking…", hint: "", target: nil)
                continue
            }
            if Task.isCancelled || !ok { return }
            if alreadyFine {
                alreadyFine = false
                let what = pick.candidate.context.lowercased()
                if !fixes.isEmpty { nextFix(note: "Your apps can already use the \(what). So that's not the problem."); return }
                show(.done, label: "All done", text: "Your apps can already use the \(what).", hint: "That part is fine.", target: nil); return
            }
            done.append(pick.candidate.source == "menu" ? "chose \(pick.candidate.path)" : "clicked \(Planner.key(pick.candidate))")
            if isFinal(pick.candidate) || pick.candidate.role == "switch" { finish(); return }   // flipping a switch ends a settings fix
        }
        if !Task.isCancelled { finish() }
    }

    /// One decision on the current screen: stay in this app, or (first step only) send the person to another.
    func decide(_ state: ScreenState, app: NSRunningApplication) async throws -> Planner.Pick? {
        let g = goal.lowercased()
        let mentionsThis = ["this ", "ito", "ito ", "yung "].contains { g.contains($0) }
        let current = app.localizedName ?? state.frontApp
        // Settings jobs (camera for a video call, Wi-Fi, text size…) go to System Settings, then its pane.
        // "yung" is just "the" in Taglish; only "this"/"ito" pins the request to the app in front.
        let words = Set(g.components(separatedBy: CharacterSet.alphanumerics.inverted))
        let pinned = words.contains("this") || words.contains("ito")
        if done.isEmpty, settingsPane == nil, !pinned || current == "System Settings" {
            settingsPane = await SettingsRoute.pane(for: goal) ?? ""
            log("SETTINGS pane=\(settingsPane ?? "")")
        }
        if let pane = settingsPane, !pane.isEmpty {
            if current != "System Settings" {
                expectedApp = "System Settings"
                if let icon = state.candidates.first(where: { $0.source == "dock" && $0.label == "System Settings" }) {
                    return Planner.Pick(candidate: icon, confidence: 0.9, runnersUp: [])
                }
                // Not in the Dock: the Apple menu always has it.
                let apple = Candidate(id: 0, source: "menu", role: "menu item", label: "System Settings…", context: "Apple",
                                      path: "Apple > System Settings…", frame: nil, enabled: true)
                return Planner.Pick(candidate: apple, confidence: 0.9, runnersUp: [])
            }
            if current == "System Settings", !done.contains(where: { $0.contains(pane) }),
               let row = state.candidates.first(where: { $0.source == "window" && $0.role == "row" && $0.label == pane }) {
                return Planner.Pick(candidate: row, confidence: 0.9, runnersUp: [])
            }
        }
        // The journey's memory: the next planned name, if it's on screen exactly (never menus; Laya is better there).
        if waypoints == nil {
            waypoints = await Orchestrator.plan(goal: goal, app: current)
            log("WAYPOINTS \(waypoints ?? [])")
        }
        if let wps = waypoints, !wps.isEmpty {
            let clicked = done.joined(separator: "|").lowercased()
            let pending = wps.drop(while: { w in clicked.contains("\"\(w.lowercased())\"") || Orchestrator.same(w, current) })
            if let next = pending.first {
                let pool = focus(state).filter { $0.source != "menu" } + state.candidates.filter { $0.source == "dock" && done.isEmpty }
                if let hit = pool.first(where: { Orchestrator.same($0.label, next) && !rejected.contains(Planner.key($0)) }) {
                    log("WAYPOINT \(next)")
                    if hit.source == "dock" { expectedApp = hit.label }
                    return Planner.Pick(candidate: hit, confidence: 0.9, runnersUp: [])
                }
            }
        }
        // Stay first: the app in front is usually where the person wants help ("this photo").
        let here = try await planner.choose(app: state.frontApp, goal: goal, done: done, candidates: focus(state))
        let namesOther = Self.namedApp(in: g, state: state, current: app.localizedName ?? "")
        if done.isEmpty, !mentionsThis, namesOther || (here?.confidence ?? 0) < 0.35,
           let route = try await routeToApp(state, current: app.localizedName ?? state.frontApp),
           namesOther || route.confidence >= 0.6 {
            return route
        }
        return here
    }

    /// DEV: first-step decisions for many goals on one screen, no overlay and no clicks (real-use-case tests).
    func planBatch(app: NSRunningApplication, goals: [String]) async -> [[String: String]] {
        let state = await read(app)
        var out: [[String: String]] = []
        for g in goals {
            goal = g; done = []; rejected = []; settingsPane = nil; waypoints = nil
            let risk = await planner.risky(goal: g)
            let pick = try? await decide(state, app: app)
            let route = try? await routeToApp(state, current: app.localizedName ?? state.frontApp)
            let apple = state.candidates.contains { $0.path.hasPrefix("Apple >") }
            out.append(["goal": g, "pick": pick.map { Planner.key($0.candidate) } ?? "-",
                        "conf": pick.map { String(format: "%.2f", $0.confidence) } ?? "0",
                        "risk": String(format: "%.2f", risk), "scamRule": ScamGuard.check(goal: g) == nil ? "" : "warn",
                        "route": route.map { "\($0.candidate.label) \(String(format: "%.2f", $0.confidence))" } ?? "-",
                        "appleMenu": apple ? "yes" : "no"])
        }
        return out
    }

    /// Work on one fix of the checklist as if it were the request.
    private func beginFix(_ f: Fix) {
        goal = f.task; done = []; stepNo = 0; rejected = []; settingsPane = nil; waypoints = nil
        planLine = f.say
        log("FIX \(fixIndex + 1)/\(fixes.count) \(f.task)")
    }

    /// "Still not working" (or the fix was already in place): on to the next likely cause.
    func nextFix(note: String? = nil) {
        fixIndex += 1
        guard fixIndex < fixes.count else {
            show(.done, label: "Out of ideas", text: "I've tried what I know for this.",
                 hint: "A family member may need to look. Nothing was changed that you didn't choose.", target: nil)
            return
        }
        beginFix(fixes[fixIndex])
        task?.cancel()
        task = Task {
            if let note { self.show(.detour, label: "Okay", text: note, hint: "", target: nil); try? await Task.sleep(nanoseconds: 2_500_000_000) }
            if let front = Self.frontRegularApp() { self.app = front }
            await self.run()
        }
    }

    func finish() {
        if !fixes.isEmpty || !(settingsPane ?? "").isEmpty {
            log("FIX DONE \(fixIndex + 1) steps=\(done)")
            overlay.model.askWorked = true
            show(.done, label: "Check", text: "Try it again now. Is it working?", hint: "", target: nil)
            speakText("Try it again now. Is it working?")
            return
        }
        log("DONE steps=\(done)")
        show(.done, label: "All done", text: "Done. You did it.", hint: done.enumerated().map { "\($0.offset + 1). \(plain($0.element))" }.joined(separator: "\n"), target: nil)
        speakText("Done. You did it.")
    }

    /// Point at one candidate until the user completes it. Menu commands are walked level by level.
    private func guide(_ pick: Planner.Pick) async -> Bool {
        var c = pick.candidate
        guard let app else { return false }
        if c.source == "menu" { return await guideMenu(c, app: app) }
        if c.source == "dock" { expectedApp = c.label }
        // Below or above the visible part of a list: ask for a scroll first, then ring it once it's in view.
        // Mostly visible inside the window (a row half under the edge still counts).
        func inView(_ f: CGRect, _ w: CGRect) -> Bool { let i = f.intersection(w.insetBy(dx: 0, dy: 8)); return !i.isNull && i.height >= f.height * 0.6 }
        if c.source == "window", let f = c.frame.map(rect), let win = MenuProbe.frontWindowFrame(app), !inView(f, win) {
            let key = Planner.key(c)
            var lastText = ""
            var frame = f, w = win
            while !Task.isCancelled {
                // Re-aim every look: if they scrolled past it, say so and point the other way.
                let down = frame.midY > w.midY
                let text = down ? "Scroll down until you see **\(c.label)**." : (lastText.isEmpty ? "Scroll up until you see **\(c.label)**."
                                                                                              : "Scroll back up a little to **\(c.label)**.")
                if text != lastText {
                    log("SCROLL \(down ? "down" : "up") to \(c.label)")
                    show(.guiding, label: "Step \(stepNo)", text: text, hint: "Use two fingers on the trackpad, or the mouse wheel.", target: nil)
                    lastText = text
                }
                try? await Task.sleep(nanoseconds: 350_000_000)
                if notThis { return false }
                let s = await read(app)
                guard let n = s.candidates.first(where: { Planner.key($0) == key }), let nf = n.frame.map(rect),
                      let nw = MenuProbe.frontWindowFrame(app) else { continue }
                frame = nf; w = nw
                if inView(nf, nw) { c = n; log("SCROLL found \(c.label)"); break }
            }
        }

        // A list of app switches (Camera, Microphone…) and the request names none of them: only the person knows
        // which app they call with. Say so, and any switch in that list counts.
        let siblings = lastState?.candidates.filter { $0.role == "switch" && $0.context == c.context } ?? []
        if c.role == "switch", siblings.count >= 3, !siblings.contains(where: { goal.lowercased().contains($0.label.lowercased()) }) {
            // Every app here is already allowed: this isn't the problem. Say so instead of asking for a no-op.
            if siblings.allSatisfy({ $0.on == true }) {
                log("ALREADY ON \(c.context)")
                alreadyFine = true
                return true
            }
            let frames = siblings.compactMap { $0.frame.map(rect) }
            let column = frames.dropFirst().reduce(frames.first ?? .null) { $0.union($1) }
            show(.guiding, label: "Step \(stepNo)", text: "Turn on the switch next to the app you use for the call.",
                 hint: "For example Zoom, FaceTime or Google Chrome.", target: column.isNull ? nil : column)
            _ = ClickWatcher.shared.drain()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 150_000_000)
                if notThis { return false }
                for e in ClickWatcher.shared.drain() { if case .click(let p) = e, frames.contains(where: { $0.hit(p) }) {
                    try? await Task.sleep(nanoseconds: 400_000_000); await confirm(keepRing: false); return true } }
            }
            return false
        }
        if pick.confidence < 0.3, !pick.runnersUp.isEmpty {
            overlay.model.candidates = ([c] + pick.runnersUp.prefix(1)).compactMap { $0.frame.map(rect) }
            show(.notSure, label: "Step \(stepNo)", text: "It's one of these. Pick either one.", hint: "", target: nil)
        } else {
            let (text, hint) = phrase(c)
            show(.guiding, label: "Step \(stepNo)", text: text, hint: hint, target: c.frame.map(rect))
        }
        doneTyping = false
        _ = ClickWatcher.shared.drain()
        var ring = c.frame.map(rect)
        let typing = ["text field", "text area", "search field", "combo box"].contains(c.role)
        var clickedIn = false
        let key = Planner.key(c)
        let startSig = c.source == "window" ? await signature(app) : ""
        var tick = 0, offscreen = false
        waiting: while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 120_000_000)
            if notThis { return false }
            tick += 1
            // Follow the target while the person scrolls; if it leaves the window, ask them to bring it back.
            if c.source == "window", tick % 4 == 0, [.guiding, .detour].contains(overlay.model.mode) || offscreen {
                let s = await read(app)
                if let n = s.candidates.first(where: { Planner.key($0) == key }), let nf = n.frame.map(rect),
                   let w = MenuProbe.frontWindowFrame(app) {
                    let i = nf.intersection(w.insetBy(dx: 0, dy: 8))
                    let visible = !i.isNull && i.height >= nf.height * 0.6
                    if visible, offscreen || ring != nf {
                        ring = nf; offscreen = false
                        let (t, h) = phrase(c)
                        show(.guiding, label: "Step \(stepNo)", text: t, hint: h, target: nf)
                    } else if !visible, !offscreen {
                        offscreen = true; ring = nil
                        let down = nf.midY > w.midY
                        show(.guiding, label: "Step \(stepNo)", text: "Scroll \(down ? "down" : "back up") to **\(c.label)**.",
                             hint: "Use two fingers on the trackpad, or the mouse wheel.", target: nil)
                    }
                }
            }
            if doneTyping { break }
            if c.source == "dock", Self.frontRegularApp()?.localizedName == c.label { break }
            // The person went to another app: the ring would float over it. Wait quietly until they're back.
            if c.source == "window", let front = Self.frontRegularApp(), front != app {
                let name = app.localizedName ?? "your app"
                show(.detour, label: "Paused", text: "I'll wait. Go back to **\(name)** when you're ready.", hint: "Nothing has been changed.", target: nil)
                while !Task.isCancelled, let f = Self.frontRegularApp(), f != app { try? await Task.sleep(nanoseconds: 400_000_000) }
                _ = ClickWatcher.shared.drain()
                let (t, h) = phrase(c)
                show(.guiding, label: "Step \(stepNo)", text: t, hint: h, target: ring)
                continue
            }
            for e in ClickWatcher.shared.drain() {
                switch e {
                case .click(let p):
                    if let r = ring, r.hit(p) {
                        if typing { clickedIn = true; continue }   // in the box: now wait for Enter
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        break waiting
                    }
                    // They clicked something else and the screen moved on (often the right thing, just outside the ring):
                    // carry on from the new screen instead of insisting.
                    if c.source == "window", !startSig.isEmpty, !overlay.cardFrame.contains(p) {
                        try? await Task.sleep(nanoseconds: 700_000_000)
                        if await signature(app) != startSig { log("MOVED ON after click outside ring"); movedOn = true; break waiting }
                    }
                    if overlay.model.mode == .guiding, let r = ring, !overlay.model.spotlight, !overlay.cardFrame.contains(p) {
                        let (text, _) = phrase(c)
                        show(.detour, label: "Small detour", text: "That's okay. " + text, hint: "Nothing has changed.", target: r)
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                            if self.overlay.model.mode == .detour { let (t, h) = self.phrase(c); self.show(.guiding, label: "Step \(self.stepNo)", text: t, hint: h, target: r) }
                        }
                    }
                case .enter:
                    if typing && clickedIn || typing { break waiting }
                }
            }
        }
        if Task.isCancelled { return false }
        if movedOn { movedOn = false; return true }
        await confirm(keepRing: !isFinal(c) && c.role != "list choice")   // a chosen list item vanishes with its list
        return true
    }

    private func guideMenu(_ c: Candidate, app home: NSRunningApplication) async -> Bool {
        let parts = c.path.components(separatedBy: " > ")
        var level = 0
        var target: CGRect?
        _ = ClickWatcher.shared.drain()
        while !Task.isCancelled {
            if notThis { return false }
            // The Apple menu is the same in every app: follow whichever app is in front for it.
            let app = parts[0] == "Apple" ? (Self.frontRegularApp() ?? home) : home
            let openMenu = MenuProbe.openMenuTitle(app)
            let clicks = ClickWatcher.shared.drain().compactMap { e -> CGPoint? in if case .click(let p) = e { return p }; return nil }
            if level == 0 {
                if openMenu == parts[0] { level = 1; target = nil; log("MENU opened \(parts[0])"); continue }   // the bar ring no longer counts
                let bar = MenuProbe.barItem(app, title: parts[0])
                target = bar?.frame
                var hint = bar.map { $0.left.isEmpty ? "It's at the very top of your screen." : "It's at the very top of your screen, after \($0.left)." } ?? ""
                if parts[0] == "Apple" { hint = "It's the Apple logo in the top-left corner of your screen." }
                if let other = openMenu, other != parts[0] {
                    show(.detour, label: "Small detour", text: "That's okay. Click **\(parts[0])** instead.",
                         hint: hint, target: bar?.frame)
                } else if overlay.model.mode != .guiding || overlay.model.target != bar?.frame {
                    show(.guiding, label: "Step \(stepNo)", text: parts[0] == "Apple" ? "Click the **Apple logo**." : "Click **\(parts[0])**.", hint: hint, target: bar?.frame)
                }
            } else {
                let last = level == parts.count - 1
                // The final item counts only if the person clicked inside its ring.
                if !clicks.isEmpty { log("MENU clicks=\(clicks.map { "(\(Int($0.x)),\(Int($0.y)))" }) level=\(level) target=\(target.map { "\($0)" } ?? "-")") }
                if last, let t = target, clicks.contains(where: t.hit) {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    await confirm(keepRing: false); return true
                }
                if openMenu != parts[0] { level = 0; continue }   // closed without choosing: start over, never "correct"
                if let f = MenuProbe.itemFrame(app, path: Array(parts[0...level])) {
                    if !last, MenuProbe.itemFrame(app, path: Array(parts[0...level + 1])) != nil { level += 1; continue }
                    target = f   // the whole row counts as a hit
                    let ring = f.insetBy(dx: 5, dy: 0)   // drawn inside the menu, like the system highlight
                    let name = parts[level]
                    let text = last ? "Click **\(name)**." : "Point to **\(name)**, then wait for the list."
                    if overlay.model.target != ring || overlay.model.instruction != text {
                        overlay.keepOut = MenuProbe.openMenuFrames(app)
                        show(.guiding, label: "Step \(stepNo)", text: text, hint: last ? "" : "A second list will slide out.", target: ring)
                    }
                } else if overlay.model.instruction != "Click **\(parts[level])**." {
                    // Open, but the item isn't readable: still say what to click rather than keep the old ring.
                    show(.guiding, label: "Step \(stepNo)", text: "Click **\(parts[level])**.", hint: "It's in the list that just opened.", target: nil)
                }
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
        }
        return false
    }

    private var lastMenuSig = ""
    private func didLeaveMenu(_ app: NSRunningApplication) async -> Bool {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return MenuProbe.openMenuTitle(app) == nil
    }

    /// `keepRing`: false when the clicked thing just went away (a menu item, a button that closes its dialog);
    /// a green ring floating over empty space looks like a mistake.
    private func confirm(keepRing: Bool = true) async {
        overlay.keepOut = []
        let m = overlay.model
        if !keepRing { m.target = nil }
        m.plan = ""
        m.mode = .confirmed
        m.label = "Step \(stepNo) · Done"
        m.instruction = "That's right."
        m.hint = ""
        overlay.update()
        try? await Task.sleep(nanoseconds: 900_000_000)
    }

    private func stuck() {
        overlay.model.spotlight = true
        if overlay.model.hint.isEmpty { overlay.model.hint = "It's inside the purple ring." }
        overlay.update()
        speak()
    }

    /// If the goal belongs to another app in the Dock, point at that Dock icon first.
    private func routeToApp(_ s: ScreenState, current: String) async throws -> Planner.Pick? {
        var dock: [String: Candidate] = [:]
        for c in s.candidates where c.source == "dock" && !c.label.contains(" — ") && !c.label.contains(" - ") && !["Trash", "Apps"].contains(c.label) {
            if dock[c.label] == nil { dock[c.label] = c }
        }
        let names = s.candidates.filter { dock[$0.label]?.id == $0.id }.map(\.label)   // Dock order
        guard !names.isEmpty else { return nil }
        let (choice, confidence) = try await planner.pickApp(goal: goal, current: current, apps: names)
        log("ROUTE \(choice) conf=\(String(format: "%.2f", confidence))")
        guard choice != current, confidence >= 0.5, let icon = dock[choice] else { return nil }
        return Planner.Pick(candidate: icon, confidence: confidence, runnersUp: [])
    }

    /// True when the goal names an app in the Dock other than the current one ("in Safari", "settings").
    static func namedApp(in g: String, state: ScreenState, current: String) -> Bool {
        let aliases = ["settings": "System Settings", "safari": "Safari", "chrome": "Google Chrome", "zoom": "zoom.us",
                       "messenger": "Messenger", "viber": "Viber", "mail": "Mail", "photos": "Photos", "facetime": "FaceTime"]
        let dock = Set(state.candidates.filter { $0.source == "dock" }.map { $0.label.lowercased() })
        for (word, app) in aliases where g.contains(word) && app.lowercased() != current.lowercased() && dock.contains(app.lowercased()) {
            return true
        }
        return dock.contains { $0.count > 3 && $0 != current.lowercased() && g.contains($0) }
    }

    /// Which candidates the model should weigh right now, mirroring how it was trained:
    /// an open dialog wins; the first step is about menus; later steps add window controls.
    private func focus(_ s: ScreenState) -> [Candidate] {
        // A pop-up list is open: the next step is one of its choices, nothing else.
        let choices = s.candidates.filter { $0.role == "list choice" && $0.enabled && !rejected.contains(Planner.key($0)) }
        if !choices.isEmpty { return choices }
        // Sidebar rows in save/export panels are the person's folders, not steps.
        let dialog = s.candidates.filter { $0.source == "window" && $0.context.hasSuffix("dialog") && $0.role != "row" }
        if !dialog.isEmpty {
            let fresh = dialog.filter { !rejected.contains(Planner.key($0)) && !done.contains("clicked \(Planner.key($0))") }
            return fresh.isEmpty ? dialog : fresh
        }
        // App > Services lists add-ons installed on this Mac ("Ask Claude"…), never a beginner's step.
        let menus = s.candidates.filter { $0.source == "menu" && !Self.isPersonal($0.path)
                                          && $0.path.components(separatedBy: " > ").dropFirst().first != "Services" }
        let ok = { (c: Candidate) in !self.rejected.contains(Planner.key(c)) && !self.done.contains("clicked \(Planner.key(c))") }
        if done.isEmpty { return menus.filter(ok) }   // other apps are handled by routeToApp first
        return (s.candidates.filter { $0.source == "window" && $0.role != "menu button" } + menus).filter(ok)
    }

    /// Same rule as ml/make_fixtures.py is_personal(): menu entries that are user data (recent files,
    /// window titles, history, accounts), not commands. The model never trained on them.
    static let staticWindow = ["Close", "Minimize", "Zoom", "Fill", "Center", "Move & Resize", "Full Screen Tile",
                               "Remove Window", "Bring All to Front", "Arrange in Front", "Merge All Windows", "Move Tab",
                               "Show ", "Hide ", "Pin Tab", "Enter Full Screen", "Move Window", "Tile", "Window"]
    static func frontRegularApp() -> NSRunningApplication? {
        guard let front = NSWorkspace.shared.frontmostApplication, front.activationPolicy == .regular,
              front.bundleIdentifier != Bundle.main.bundleIdentifier else { return nil }
        return front
    }

    static func isPersonal(_ path: String) -> Bool {
        let parts = path.components(separatedBy: " > ")
        if path.contains("@") || path.contains("Apple Account") || path.contains(" — ") { return true }
        if parts.dropFirst().dropLast().contains(where: { p in
            ["recent", "recently", "favorites", "bookmarks bar", "reading list"].contains { p.lowercased().contains($0) } }) {
            return parts.last != "Clear Menu"
        }
        if parts.first == "History", parts.count >= 3 { return true }
        if parts.first == "Window", parts.count == 2 { return !staticWindow.contains { parts[1].hasPrefix($0) } }
        return false
    }

    // MARK: - Copy

    private func phrase(_ c: Candidate) -> (String, String) {
        switch c.source {
        case "dock": return ("Click **\(c.label)** in the Dock.", "The Dock is the row of icons at the bottom of your screen.")
        case "statusbar": return ("Click the **\(c.label)** icon at the top right.", "It's in the strip of small icons next to the clock.")
        default: break
        }
        switch c.role {
        case "text field", "text area", "search field", "combo box":
            let size = goal.lowercased().contains("small") || goal.lowercased().contains("email")
            return ("Click in the **\(c.label)** box and type the new value.",
                    size ? "For an email, 1200 is a good width. Then press Enter." : "Then press Enter.")
        case "switch", "checkbox": return ("Click **\(c.label)** to turn it on or off.", "")
        case "slider": return ("Drag the **\(c.label)** slider.", "Left is less, right is more.")
        case "pop-up menu": return ("Click **\(c.label)** and pick from the list.", "")
        case "list choice": return ("Click **\(c.label)** in the list.", "")
        case "row": return ("Click **\(c.label)** in the list on the left.", "")
        case "link": return ("Click **\(c.label)**.", "")
        default: return ("Click **\(c.label)**.", c.context.isEmpty ? "" : "It's in \(c.context).")
        }
    }

    private func isFinal(_ c: Candidate) -> Bool {
        if c.source == "menu" { return !c.label.hasSuffix("…") && !c.label.hasSuffix("...") }
        return ["OK", "Done", "Save", "Export", "Print", "Apply", "Send", "Continue", "Close"].contains(c.label)
    }

    // MARK: - Helpers

    func show(_ mode: OverlayModel.Mode, label: String, text: String, hint: String, target: CGRect?) {
        let m = overlay.model
        // The plan sentence sits above the step as a quiet caption on step 1 instead of lengthening the hint.
        m.plan = mode == .guiding && stepNo == 1 ? (planLine ?? "") : ""
        if mode != .done { m.askWorked = false }
        m.mode = mode; m.label = label; m.instruction = text; m.hint = hint; m.target = target; m.spotlight = false
        m.showDone = mode == .guiding && hint.contains("Press Done")
        overlay.update()
        if mode == .guiding || mode == .detour || mode == .notSure { speak() }
    }

    private func speak() { let m = overlay.model; speakText([m.plan, plain(m.instruction), plain(m.hint)].filter { !$0.isEmpty }.joined(separator: " ")) }

    func speakText(_ s: String) {
        guard readAloud else { return }
        speech.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: s)
        u.rate = 0.45
        speech.speak(u)
    }

    func plain(_ s: String) -> String { s.replacingOccurrences(of: "**", with: "") }

    private func rect(_ f: [Double]) -> CGRect { CGRect(x: f[0], y: f[1], width: f[2], height: f[3]) }

    private func read(_ app: NSRunningApplication) async -> ScreenState {
        await Task.detached { ScreenReader.state(of: app, maxPerWindow: 300) }.value
    }

    /// A cheap fingerprint of "what's on screen": windows + visible window controls.
    private func signature(_ app: NSRunningApplication) async -> String {
        let s = await read(app)
        let keys = s.candidates.filter { $0.source == "window" }.map(Planner.key)
        return s.windowTitles.joined(separator: "|") + "#" + String(keys.joined(separator: "|").hashValue)
    }

    func markDoneTyping() { doneTyping = true }

    func log(_ s: String) {
        let line = "\(Date()) \(s)\n"
        if let h = FileHandle(forWritingAtPath: "/tmp/gabay.log") { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); h.closeFile() }
        else { FileManager.default.createFile(atPath: "/tmp/gabay.log", contents: line.data(using: .utf8)) }
    }
}

extension Notification.Name { static let gabayAskAgain = Notification.Name("gabayAskAgain") }

/// Reads menu state directly (fast enough to poll): which menu is open, menu bar item frames.
enum MenuProbe {
    /// The app's front window, in AX coordinates.
    static func frontWindowFrame(_ app: NSRunningApplication) -> CGRect? {
        let root = AXUIElementCreateApplication(app.processIdentifier)
        guard let w: AXUIElement = AXReader.attr(root, kAXFocusedWindowAttribute) ?? AXReader.attr(root, kAXMainWindowAttribute),
              let f = AXReader.visibleFrame(w) else { return nil }
        return CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
    }

    static func bar(_ app: NSRunningApplication) -> [AXUIElement] {
        let root = AXUIElementCreateApplication(app.processIdentifier)
        guard let bar: AXUIElement = AXReader.attr(root, kAXMenuBarAttribute) else { return [] }
        return AXReader.children(bar)
    }

    static func barItem(_ app: NSRunningApplication, title: String) -> (frame: CGRect, left: String, right: String)? {
        let items = bar(app)
        let titles = items.map { AXReader.string($0, kAXTitleAttribute) ?? "" }
        guard let i = titles.firstIndex(of: title), let f = AXReader.visibleFrame(items[i]) else { return nil }
        let left = i > 1 ? titles[i - 1] : ""          // index 0 is the Apple menu
        let right = i + 1 < titles.count ? titles[i + 1] : ""
        return (CGRect(x: f[0], y: f[1], width: f[2], height: f[3]), left, right)
    }

    /// Title of the menu bar menu that is currently open, if any.
    static func openMenuTitle(_ app: NSRunningApplication) -> String? {
        for item in bar(app) {
            for menu in AXReader.children(item) where AXReader.role(menu) == "AXMenu" {
                if let first = AXReader.children(menu).first, AXReader.visibleFrame(first) != nil {
                    return AXReader.string(item, kAXTitleAttribute)
                }
            }
        }
        return nil
    }

    static func itemFrame(_ app: NSRunningApplication, path: [String]) -> CGRect? {
        var level = bar(app)
        var el: AXUIElement?
        // Titles can carry extras ("System Settings…  2 updates") or "..." instead of "…".
        func norm(_ t: String) -> String { t.replacingOccurrences(of: "...", with: "").replacingOccurrences(of: "…", with: "")
            .trimmingCharacters(in: .whitespaces).lowercased() }
        for name in path {
            let titles = level.map { AXReader.string($0, kAXTitleAttribute) ?? "" }
            guard let i = titles.firstIndex(of: name) ?? titles.firstIndex(where: { norm($0) == norm(name) })
                    ?? titles.firstIndex(where: { !norm(name).isEmpty && norm($0).hasPrefix(norm(name)) }) else { return nil }
            let hit = level[i]
            el = hit
            level = AXReader.children(hit).filter { AXReader.role($0) == "AXMenu" }.flatMap { AXReader.children($0) }
        }
        guard let el, let f = AXReader.visibleFrame(el) else { return nil }
        return CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
    }

    static func openMenuFrames(_ app: NSRunningApplication) -> [CGRect] {
        var out: [CGRect] = []
        func walk(_ el: AXUIElement, _ d: Int) {
            guard d < 4 else { return }
            for m in AXReader.children(el) where AXReader.role(m) == "AXMenu" {
                if let f = AXReader.visibleFrame(m) { out.append(CGRect(x: f[0], y: f[1], width: f[2], height: f[3])) }
                for item in AXReader.children(m) { walk(item, d + 1) }
            }
        }
        for item in bar(app) { walk(item, 0) }
        return out
    }
}
