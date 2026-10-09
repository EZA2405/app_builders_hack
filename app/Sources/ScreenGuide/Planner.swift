import Foundation

/// Picks the next control with the local Laya model (laya-serve on 127.0.0.1:8766), using the
/// same state text, candidate formats and 16-wide tournament as ml/bench_localjev.py.
struct Planner {
    var url = URL(string: "http://127.0.0.1:8766/v1/systemone")!
    var model = ProcessInfo.processInfo.environment["GABAY_MODEL"] ?? "guide"
    var group = 16
    var keep = 3

    struct Pick { let candidate: Candidate; let confidence: Double; let runnersUp: [Candidate] }

    /// The string the model sees for each candidate (matches the training data formats).
    static func key(_ c: Candidate) -> String {
        switch c.source {
        case "menu": return c.path                                   // "Tools > Adjust Size…"
        case "dock": return "dock icon \"\(c.label)\""
        case "statusbar": return "menu bar icon \"\(c.label)\""
        default: return c.context.isEmpty ? "\(c.role) \"\(c.label)\"" : "\(c.role) \"\(c.label)\" · \(c.context)"
        }
    }

    static func stateText(app: String, goal: String, done: [String]) -> String {
        var s = "A non-technical person is using the Mac app \(app). Their goal: \"\(goal)\""
        if !done.isEmpty { s += " Already done: " + done.joined(separator: "; ") + "." }
        return s
    }

    func choose(app: String, goal: String, done: [String], candidates: [Candidate]) async throws -> Pick? {
        var byKey: [String: Candidate] = [:]
        for c in candidates where c.enabled { if byKey[Self.key(c)] == nil { byKey[Self.key(c)] = c } }
        var keys = Array(byKey.keys).sorted { (byKey[$0]!.id) < (byKey[$1]!.id) }   // screen/menu order
        guard !keys.isEmpty else { return nil }
        let state = Self.stateText(app: app, goal: goal, done: done)
        let instructions = done.isEmpty ? "Which \(app) menu command accomplishes the person's goal?"
                                        : "Which element on this page should the person use next?"
        // Tournament: chunks of `group`, keep the top `keep` of each, repeat until one round.
        while keys.count > group {
            var next: [String] = []
            for chunk in stride(from: 0, to: keys.count, by: group).map({ Array(keys[$0..<min($0 + group, keys.count)]) }) {
                let probs = try await ask(state: state, instructions: instructions, options: chunk).probs
                next += probs.sorted { $0.value > $1.value }.prefix(keep).map(\.key)
            }
            keys = next
        }
        let final = try await ask(state: state, instructions: instructions, options: keys)
        let ranked = final.probs.sorted { $0.value > $1.value }.compactMap { byKey[$0.key] }
        guard let best = byKey[final.choice] ?? ranked.first else { return nil }
        return Pick(candidate: best, confidence: final.confidence, runnersUp: Array(ranked.dropFirst().prefix(2)))
    }

    private func ask(state: String, instructions: String, options: [String]) async throws
        -> (choice: String, confidence: Double, probs: [String: Double]) {
        var crit: [String: String] = [:]
        for o in options { crit[o] = o }
        let body: [String: Any] = ["model": model, "state": state,
                                   "questions": ["next_command": ["type": "choice", "instructions": instructions, "criteria": crit]]]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30
        let (data, _) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let answers = (json["answers"] as? [String: Any]) ?? json
        let a = answers["next_command"] as? [String: Any] ?? [:]
        let probs = (a["probabilities"] as? [String: Double]) ?? [:]
        return (a["choice"] as? String ?? probs.max { $0.value < $1.value }?.key ?? "",
                a["confidence"] as? Double ?? 0, probs)
    }
}
