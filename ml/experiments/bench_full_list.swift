import Foundation
import FoundationModels

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

func plan(_ goal: String) async throws {
  let target = DynamicGenerationSchema(name: "Target", anyOf: paths)
  let root = DynamicGenerationSchema(name: "Plan", properties: [
    .init(name: "reasoning", description: "brief: which command accomplishes the goal", schema: DynamicGenerationSchema(type: String.self)),
    .init(name: "target", description: "the exact command path that accomplishes the goal", schema: target),
  ])
  let schema = try GenerationSchema(root: root, dependencies: [target])
  let s = LanguageModelSession(instructions: "You help a non-technical person use the Mac app Preview. Given their goal and the list of every command available in the app, choose the one command that accomplishes the goal.")
  let t = Date()
  let r = try await s.respond(to: "Goal: \(goal)\nAvailable commands:\n" + paths.joined(separator: "\n"), schema: schema)
  print(String(format: "%5.2fs", Date().timeIntervalSince(t)), "|", goal, "->", try r.content.value(String.self, forProperty: "target"))
}
for g in ["make this photo smaller so I can email it", "make this photo smaller so I can email it", "turn the picture the right way up, it's sideways", "save a copy as a JPEG", "the photo is too dark, make it brighter", "print this", "cut out just my face from the picture", "make a copy of this file", "I want to draw a circle on the photo", "where was this photo taken?"] {
  try await plan(g)
}
