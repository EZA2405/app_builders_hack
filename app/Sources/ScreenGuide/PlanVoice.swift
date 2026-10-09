import Foundation
import FoundationModels

/// Apple's on-device model words the plan for a route Laya already chose ("I'll save a smaller copy of
/// your photo."). It never chooses what to click — measured: rewriting goals for the picker hurt accuracy
/// (ml/RESULTS.md) — it only explains, so a surprising-but-valid route doesn't feel like a mistake.
@Generable
struct PlanLine {
    @Guide(description: "One warm, plain sentence (max 14 words) telling an older person what you will help them do, naming the result they get. No app jargon, no menu names.")
    var sentence: String
}

enum PlanVoice {
    static var available: Bool { SystemLanguageModel.default.availability == .available }

    static func prewarm() {
        guard available else { return }
        LanguageModelSession().prewarm()
    }

    /// e.g. goal "make this photo smaller so I can email it", route "File > Export…" -> "I'll help you save a smaller copy of your photo to email."
    static func plan(goal: String, route: String) async -> String? {
        guard available else { return nil }
        let session = LanguageModelSession(instructions: """
        You are a patient helper for older people using a Mac. Another part of the app already decided which \
        menu command or button to use. In one short sentence starting with "I'll help you", say what this will \
        do for the person, in everyday words. Do not mention menus, commands or clicking.
        """)
        let task = Task { try? await session.respond(to: "Their request: \(goal)\nThe app will use: \(route)", generating: PlanLine.self) }
        // Never hold the guide up for more than ~2.5 s; the step works without the sentence.
        let timeout = Task { try? await Task.sleep(nanoseconds: 2_500_000_000); task.cancel() }
        let r = await task.value
        timeout.cancel()
        return r?.content.sentence
    }
}
