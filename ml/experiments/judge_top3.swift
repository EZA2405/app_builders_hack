// Second opinion from Apple's on-device model: given Laya's final 3, which one does the person mean?
// Experiment only (val set). Usage: swiftc -O judge_top3.swift -o /tmp/sg/judge/judge && /tmp/sg/judge/judge in.json out.json
import Foundation
import FoundationModels

@Generable
struct Pick {
    @Guide(description: "Number of the option that does what the person wants", .range(1...3))
    var number: Int
}

struct Item: Codable { let app: String; let goal: String; let top3: [String] }

let args = CommandLine.arguments
let items = try JSONDecoder().decode([Item].self, from: Data(contentsOf: URL(fileURLWithPath: args[1])))
let instructions = """
You help an older person use a Mac app. You get their request and three menu commands from the app. \
Pick the one command that directly does what they asked. Prefer the most direct, everyday command, not a workaround.
"""
var out: [Int] = []
let start = Date()
for (i, it) in items.enumerated() {
    let session = LanguageModelSession(instructions: instructions)
    let opts = it.top3.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
    let r = try? await session.respond(to: "App: \(it.app)\nRequest: \(it.goal)\nCommands:\n\(opts)", generating: Pick.self)
    out.append(r?.content.number ?? 0)
    if i % 20 == 0 { FileHandle.standardError.write("\(i)/\(items.count)\n".data(using: .utf8)!) }
}
try JSONEncoder().encode(out).write(to: URL(fileURLWithPath: args[2]))
print("judged \(out.filter { $0 > 0 }.count)/\(items.count) in \(Int(Date().timeIntervalSince(start)))s")
