import Foundation
import FoundationModels
import NaturalLanguage

let menus: [String: [String]] = [
 "Preview": ["About Preview","Settings…","Hide Preview","Quit Preview"],
 "File": ["Open…","Open Recent","Close","Save","Duplicate","Rename…","Move To…","Revert To","Export…","Export as PDF…","Share","Print…"],
 "Edit": ["Undo","Redo","Cut","Copy","Paste","Delete","Select All","Deselect All","Insert","Find","Emoji & Symbols"],
 "View": ["Thumbnails","Table of Contents","Actual Size","Zoom to Fit","Zoom In","Zoom Out","Slideshow","Show Markup Toolbar","Enter Full Screen"],
 "Go": ["Previous Page","Next Page","Go to Page…","Back","Forward"],
 "Tools": ["Text Selection","Rectangular Selection","Annotate","Show Inspector","Adjust Color…","Adjust Size…","Rotate Left","Rotate Right","Flip Horizontal","Flip Vertical","Crop","Assign Profile…","Show Location Info"],
 "Window": ["Minimize","Zoom","Move Window to Left Side of Screen","Bring All to Front"],
 "Help": ["Preview Help"],
]
let order = ["Preview","File","Edit","View","Go","Tools","Window","Help"]
var paths: [String] = []
for m in order { for i in menus[m]! { paths.append("\(m) > \(i)") } }
paths += ["Toolbar > Share","Toolbar > Markup","Toolbar > Rotate","Toolbar > Search"]


let emb = NLEmbedding.sentenceEmbedding(for: .english)!
setvbuf(stdout, nil, _IOLBF, 0)
func cos(_ a: [Double], _ b: [Double]) -> Double { var d = 0.0, na = 0.0, nb = 0.0; for i in 0..<a.count { d += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i] }; return d / (na.squareRoot()*nb.squareRoot() + 1e-9) }
// embed the item label (strip "Menu > ") for better matching
let pvec = paths.map { emb.vector(for: String($0.split(separator: ">").last!).trimmingCharacters(in: .whitespaces)) ?? [] }
func shortlist(_ q: String, _ k: Int) -> [String] {
  guard let qv = emb.vector(for: q) else { return [] }
  return zip(paths, pvec).map { ($0, $1.isEmpty ? -1 : cos(qv, $1)) }.sorted { $0.1 > $1.1 }.prefix(k).map { $0.0 }
}
func pick(_ goal: String) async throws {
  let t = Date()
  // Stage 1: model restates goal in app-command vocabulary (free text, short)
  let s1 = LanguageModelSession(instructions: "Rewrite the user's goal as the name of the menu command an image viewer app would use for it, like 'Adjust Size', 'Rotate', 'Export', 'Adjust Color', 'Crop', 'Annotate'. Reply with 2-4 words only.")
  let cmd = try await s1.respond(to: goal).content
  let cands = Array(Set(shortlist(goal, 4) + shortlist(cmd, 4)))
  let target = DynamicGenerationSchema(name: "Target", anyOf: cands)
  let root = DynamicGenerationSchema(name: "Plan", properties: [
    .init(name: "target", description: "the command that accomplishes the goal", schema: target)])
  let schema = try GenerationSchema(root: root, dependencies: [target])
  let s2 = LanguageModelSession(instructions: "Choose the one Preview app command that accomplishes the user's goal.")
  let r = try await s2.respond(to: "Goal: \(goal)\nCommands:\n" + cands.joined(separator: "\n"), schema: schema)
  print(String(format: "%5.2fs", Date().timeIntervalSince(t)), "|", goal, "| rewrite:", cmd, "->", try r.content.value(String.self, forProperty: "target"))
}
let t0 = Date(); _ = shortlist("warm", 1); print("embed setup", Date().timeIntervalSince(t0))
for g in ["make this photo smaller so I can email it", "turn the picture the right way up, it's sideways", "save a copy as a JPEG", "the photo is too dark, make it brighter", "print this", "cut out just my face from the picture", "make a copy of this file", "I want to draw a circle on the photo", "where was this photo taken?", "make the picture bigger on my screen"] {
  try await pick(g)
}
