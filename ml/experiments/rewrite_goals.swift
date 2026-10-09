// Rewrites what a person typed into a short, plain action using Apple's on-device model
// (FoundationModels, macOS 26). Experiment: does giving Laya this rewrite improve its picks?
// Usage: swiftc -O rewrite_goals.swift -o rewrite_goals && ./rewrite_goals goals.json out.json
import Foundation
import FoundationModels

@Generable
struct Intent {
    @Guide(description: "The action as an app menu would name it, in plain English, max 8 words, e.g. 'Resize the image', 'Rotate the photo left', 'Export as PDF', 'Make the text bigger'. Translate Tagalog/Taglish to English.")
    var action: String
}

let args = CommandLine.arguments
let goals = try JSONDecoder().decode([String].self, from: Data(contentsOf: URL(fileURLWithPath: args[1])))
let instructions = """
You help a small model understand what an older, non-technical person wants to do on their Mac.
Restate their request as the single action a Mac app menu command would perform. Keep what it acts on
(photo, text, window, file). Prefer the most direct, everyday action a beginner means, not a workaround.
"""
var out: [String: String] = [:]
let start = Date()
for (i, g) in goals.enumerated() {
    let session = LanguageModelSession(instructions: instructions)   // fresh per goal: no carry-over
    if let r = try? await session.respond(to: "Request: \(g)", generating: Intent.self) {
        out[g] = r.content.action
    }
    if i % 20 == 0 { FileHandle.standardError.write("\(i)/\(goals.count)\n".data(using: .utf8)!) }
}
try JSONEncoder().encode(out).write(to: URL(fileURLWithPath: args[2]))
print("rewrote \(out.count)/\(goals.count) in \(Int(Date().timeIntervalSince(start)))s")
