# Laptop AI opportunities: Laya/Jev and two interaction hypotheses

Research date: 2026-10-09. This supersedes the phone-oriented recommendations in [the earlier winner report](AI_HACKATHON_OPPORTUNITIES.md). The winner evidence in that report remains useful. No product is selected, implementation started, or model performance measured.

The research agent's [model verification notes](MODEL_RESEARCH_NOTES.md) contain the official API/model-card links, runtime details and concrete failure cases.

## Constraints from the user and supplied materials

Build for a laptop workspace: pointer/keyboard interaction, editable state and a useful wide-screen view. Essential inputs must originate inside the app. No required Messenger, Google Calendar, cloud inference, or documents imported from other apps. Model downloads during setup are distinct from a continuing runtime dependency.

The user has set aside hardware limits for concept selection and plans a mock video. Treat the video as a storyboard, not evidence of working inference. The [briefing](AppBuildersPH%20Hackathon%202026%20Participant%20Briefing.pdf) requires a working product; the [transcript](transcript) specifies a live finalist demo at 21:02–21:37 and explicitly distinguishes it from the recorded submission at 45:43–45:57. The relevant selection criteria are usefulness 25%, meaningful local AI 25%, technical execution 20%, innovation 15%, product/demo 15%. At 44:30 the organizer allows conventional ML; a generative LLM is not required. At 20:34–20:42, the organizer allows similar ideas differentiated by execution. We should seek a distinct, useful interaction without claiming an unprecedented category.

## What Laya and Jev actually offer

The user's spellings were correct. They refer to decision models, not LLaVA or JEPA.

| | Jev | Laya |
| --- | --- | --- |
| Owner / primary source | [TypeSafe AI](https://typesafe.ai/blog/introducing-system-one-models-and-jev) | [NandhaKishorM / Convai Innovations](https://github.com/NandhaKishorM/laya) |
| Output | Typed choices, scores and yes/no probabilities | Typed choices, scores and yes/no probabilities |
| Generation | Gives up text generation | Non-autoregressive; no generated prose |
| Runtime fit | Documented hosted service; no verified public local weights | Downloadable weights, Apache-2.0; local inference supported |
| Cost interpretation | Published $0.042 per million input tokens; outputs free | No inference API charge when self-hosted; still uses hardware, energy and engineering time |
| Decision for this brief | Research reference, excluded from the essential offline path | Candidate local component, subject to task-specific evaluation |

Jev's hosted price is genuinely small in token terms: 1,000 requests of 1,000 input tokens would cost $0.042 at that list rate. That calculation excludes repeated questions, retries, other models and infrastructure. It does not satisfy the user's cloud blocker. TypeSafe's [October 7 case study](https://typesafe.ai/blog/jack-jill-jev-case-study) reports lower candidate-screening costs and comparable recall in its particular workflow; it is vendor-reported evidence, not a guarantee for our tasks.

Laya's [checkpoint table and source](https://github.com/NandhaKishorM/laya/tree/1adc59f7e371deb601fcfa18a14e25db238addcc) document 421M-parameter English and typed-decision models and a 322M multilingual model. Small relative to multi-billion-parameter generators does not establish low latency on this laptop. Upstream T4 timings are not laptop measurements. The [examples](https://github.com/NandhaKishorM/laya/blob/1adc59f7e371deb601fcfa18a14e25db238addcc/examples/README.md) distinguish loading, warm-up and inference and demonstrate offline loading after weights are available.

**The strongest caveat comes from Laya itself:** its [honest limits](https://github.com/NandhaKishorM/laya/tree/1adc59f7e371deb601fcfa18a14e25db238addcc#honest-limits) report near-chance base-model zero-shot performance on typed-decisions, with substantially better results from a checkpoint fine-tuned on that benchmark's training split. [Issue #377](https://github.com/NandhaKishorM/laya/issues/377) documents confidently wrong negation decisions. Typed output prevents malformed answer shapes; it does not prevent wrong decisions. Neither confidence thresholds nor changing labels alone solves that problem.

Consequently, design a narrow decision task, retain human preview/correction, and evaluate held-out paraphrases and negations. Laya cannot independently interpret a screenshot, generate an explanation, invent a new experiment or write code. Those functions require deterministic software, templates, or another explicitly local model. Prefer a small decision component whose benefit can be demonstrated over a rule-based baseline.

## 1. Intent Undo — reverse an experiment, preserve the work around it

**User promise:** “Undo my attempts to make this look playful; keep the wording fixes and the layout I ended up with.”

A desktop poster/diagram canvas records edits as operations with stable object IDs, before/after values and dependencies. The user experiments with fonts, colors, text and layout in an interleaved sequence. They describe the direction to reverse. The app highlights proposed removals, shows the resulting canvas beside the current one, and applies the change only after review. The result is reconstructed from actual history rather than generated from a screenshot. Users can restore the whole operation.

**Problem evidence:** a [Figma forum user](https://forum.figma.com/ask-the-community-7/does-figma-ai-agent-support-undo-55401) asks how to retain good AI changes while reverting bad ones; support's June 30 response says selective revert is unavailable in that workflow. This is a dated, specific report, not a claim about every current Figma surface. Separately, [Zed issue #19934](https://github.com/zed-industries/zed/issues/19934) requests selective undo to preserve later desired edits. CMU's [Aquamarine research](https://www.cs.cmu.edu/~NatProg/aquamarine.html) demonstrates the underlying problem and reports two informal usability studies. These sources support the problem; they do not establish purchasing demand for our editor.

**Why laptop:** precise object editing, a long operation timeline, and a side-by-side reconstruction benefit from a wide desktop canvas. Users create the entire artifact here; there is no Figma connector or imported document dependency. The demo starts from a blank canvas or a template bundled with the app.

**Meaningful Laya role:** judge short operation groups against the user's intent, returning `reverse`, `preserve`, or `review`. Include semantic context such as the affected text/object and before/after changes, rather than asking it to sort metadata that a simple property filter can already handle. Code checks dependencies, reconstructs state and presents the preview. A generator is unnecessary for this bounded workflow.

**Potential distinction:** semantic selection across interleaved history, including a visual explanation of what will survive. Selective undo is old: [Aquamarine](https://www.cs.cmu.edu/~NatProg/aquamarine.html) and [Azurite](https://www.cs.cmu.edu/~azurite/) are explicit prior art. [LingCode](https://lingcode.dev/support.html) already advertises undoing an AI step while preserving later user edits. [TensorPM's changelog](https://tensorpm.com/changelog) describes keeping/undoing individual AI changes. Our proposed interaction is intent-level selection in a self-contained consumer canvas. This scan did not establish that interaction as unique.

**Mock video:** make 15–20 interleaved edits; type the intent; show the selected history events and preview; preserve the final layout and corrected sentence while reversing earlier styling. Then correct one ambiguous selection and restore the original state. The video should make the preservation visible, not just show a chat response saying it succeeded.

**Feasibility gate:** start with text boxes, shapes and a few independently replayable properties. Test explicit preservation requests, negation, mixed intent, repeated changes to the same property, object deletion and dependencies. Report wrong selections and preview corrections separately from reconstruction correctness. If Laya cannot distinguish intent better than property filters on held-out examples, use another local classifier or stop positioning it as the differentiating intelligence. Do not claim universal undo across desktop apps.

**Assessment:** strongest everyday-use candidate and clearest fit for a decision-only model. Risk: building a compelling standalone editor is substantial, and the model's documented negation weakness directly affects the central interaction. Start with this concept only after a small held-out decision test succeeds.

## 2. Counterexample Studio — draw your prediction, then test the belief behind it

**User promise:** “Show me the smallest experiment that could prove my prediction wrong.”

A learner places objects in a 2D desktop canvas, draws their expected paths and types a claim such as “the heavier object will hit the ground first.” The app identifies a bounded misconception/test family, searches permitted parameter changes and runs a deterministic simulation. It overlays the learner's prediction and the simulated result, then lets the learner change one assumption, such as introducing drag, and repeat the comparison.

**Problem evidence:** [physics students describe difficulty visualizing mathematical concepts](https://www.reddit.com/r/PhysicsStudents/comments/1utkgj9/how_to_visualise_concepts_instead_of_relying_on/) and [struggling to connect equations with simulations](https://www.reddit.com/r/PhysicsStudents/comments/1rtmbgt/feeling_overwhelmed_trying_to_learn_computational/). These are firsthand indexed discussions, not representative prevalence estimates or evidence that this particular intervention improves learning.

**Why laptop:** an editable experiment, prediction overlay, parameter sliders and plots belong in a pointer/keyboard workspace. All inputs are created inside the app. No textbook upload, lecture recording or remote course service is required.

**Meaningful Laya role:** map the learner's short textual explanation into a small, domain-specific set of claim/test categories and identify which assumption they are invoking. The simulation and bounded search produce and verify the counterexample. Shape placement can be explicit rather than relying on vision. Explanations can be templates grounded in measured trajectories. This keeps Laya's job within text decisions; freehand scene recognition would require a separate local vision model.

**Potential distinction:** committing to a prediction before the app constructs a small contrasting experiment. Basic sketch-to-simulation is already covered by [SimVerse](https://devpost.com/software/simverse), [SimGen](https://github.com/annasba07/sim-gen) and [KineticSketch](https://1iyiwei.github.io/kinetic-sketch/). The proposed distinction is the prediction → verified counterexample → changed assumption loop. It remains an interaction hypothesis, not an established innovation claim. SimVerse is a submitted project, not a verified winner.

**Mock video:** draw different arrival times for two falling objects; state the belief; reveal a no-drag comparison where they arrive together; switch on drag and compare again. Mark predictions separately from simulated measurements. Do not depict arbitrary scientific reasoning or measured learning gains.

**Feasibility gate:** one domain, such as falls/projectiles with explicit drag settings and bounded parameter ranges. Test paraphrases and ambiguous claims, and show when no valid counterexample exists within the permitted model. The model must contribute useful interpretation beyond choosing a dropdown; the solver must verify results independently. A wrong classifier must not turn a valid student claim into a manufactured contradiction.

**Assessment:** stronger visual demo and more distinctive proposed interaction; weaker evidence for demand for the exact product. Domain design and meaningful interpretation are the main risks. It is narrower and less immediately useful than Intent Undo, but avoids pretending a general chatbot is a new learning tool.

## Brief-based comparison and recommendation

| Criterion | Intent Undo | Counterexample Studio |
| --- | --- | --- |
| Usefulness, 25% | Preserving good work while reversing mistakes is a documented editor problem | Understanding motion/equations is documented; exact intervention unvalidated |
| Local AI, 25% | Private history judged repeatedly without network calls | Private learner explanations interpreted during repeated experiments |
| Execution, 20% | Bounded history replay; dependencies and negation are hard | Bounded physics; claim interpretation and valid counterexamples are hard |
| Innovation, 15% | Intent selection is the proposed difference; selective undo already exists | Prediction-first falsification is the proposed difference; sketch simulation already exists |
| Demo, 15% | Visible preservation/reversal across interleaved edits | Visible difference between prediction and verified motion |

**Recommendation:** prioritize Intent Undo for a practical consumer product; prioritize Counterexample Studio if the team wants a more visually surprising interaction and accepts a narrower educational domain. No invented judge scores are assigned. Do not choose a concept solely because a new model can be inserted into it. Laya is worth a small task-specific evaluation, not a commitment to its accuracy.

## What actual laptop winners teach us

[Qualcomm's official Korea hackathon recap](https://www.qualcomm.com/developer/blog/2026/02/on-device-ai-developers-korea) verifies five award-winning teams from the August 2025 event. **Medly** runs on a Galaxy Book4 Edge and transforms live medical language into simpler explanations using local speech/OCR/NER and Qwen. **MyStoryPal** supports conversational story creation with Llama 3.2 3B, Stable Diffusion and CLIP on an edge PC. Their lesson is direct in-app capture and a specific interactive outcome, not that either exact app is our next recommendation.

The same recap's **E.M.Pilot** depends on email/calendar material and **File Fairy** on existing documents; exclude both under the user's blockers even though their AI runs locally. **emerGen** retrieves emergency manuals/cases; it is also a poor fit for the strict input rule. On-device inference alone does not make the whole product self-contained.

The earlier [verified winner report](AI_HACKATHON_OPPORTUNITIES.md#verified-winner-precedents) retains Chrome/Gemma precedents. In particular, The Crooked Tankard suggests separating deterministic world state from expressive AI. That is a design inference, not an organizer's explanation for the award.

## Candidates rejected and access limits

Plain screenshot search, dictation and screen guides do not address the user's request for a distinct laptop concept. Other tempting proposals also have close precedents: [SteadyMouse](https://www.steadymouse.com/) already combines tremor filtering, accidental-click blocking and icon snapping; [Whatfix Mirror](https://website.whatfix.com/products/mirror/) offers practice replicas; [Yoodli](https://support.yoodli.ai/en/articles/9628260-customizing-practice) supports critical interruptions in rehearsal. Google's [Natively Adaptive Interfaces](https://developers.google.com/natively-adaptive-interfaces) weakens any broad claim that automatically adapted desktop controls are new. These may be useful products; this investigation did not find enough differentiation to recommend them here.

Research used agent-reach's Jina Reader backend for source extraction and public web indexing for discovery. Native X access is unavailable, Exa quota is exhausted, and direct X extraction is blocked. The earlier report records one corroborated organizer post discovered through an X mirror. This follow-up does not claim native X searches, fresh X consensus or observed engagement. Model identity, availability and limitations were traced to owner-controlled repositories/docs rather than similarly named comparison/SEO sites.

No models or competitors were installed, no local timing was measured, and no product was built. The mock-video sequences above are proposed storyboards. Agent Reach 1.5.0 was checked and is current.
