# Screen-aware local AI guide: competitor research

Research date: October 9, 2026.

## Direction under consideration

The user identified the screen-aware computer guide as the most interesting direction so far. This is interest in a concept, not approval to start implementation.

Proposed experience: the user states a goal; the app examines the current screen, highlights the next control, explains one step, waits for the user to act, and checks the resulting screen. An example scenario is resizing a photo and saving a smaller copy while disconnected from the internet.

For the original problem evidence, hackathon sources, and previous research context, see [HANDOFF.md](HANDOFF.md). This document captures the subsequent competitor investigation.

## Is this computer use?

It shares the perception, planning, and verification loop of computer-use agents. In the proposed design, execution differs: an autonomous agent clicks and types; a guide explains and highlights while the user performs the actions. UI-TARS documents screenshot understanding and mouse/keyboard control; Copilot Vision explicitly documents guidance and highlighting without clicking, typing, or scrolling.

Sources: [UI-TARS Desktop](https://github.com/bytedance/UI-TARS-desktop), [Copilot Vision documentation](https://support.microsoft.com/en-au/microsoft-copilot/using-copilot-vision-with-microsoft-copilot).

Local application execution, local data storage, local model inference, and a fully offline experience are separate properties. For this hackathon, a desktop interface calling a cloud model does not by itself demonstrate meaningful on-device inference.

## Existing products

| Product | Published functionality | Inference locality and evidence |
| --- | --- | --- |
| [GuideLayer](https://guidelayer.app/) | Mac app highlights actual controls, guides users through steps, shows what changed, and saves tutorials/checklists. It markets learning with less help over time. | Its [local AI explanation](https://guidelayer.app/local-ai-assistant-mac) explicitly says local-first, not fully offline, using Codex or a Claude API key. Local storage is not evidence of on-device model inference. |
| [Metis](https://heymetis.org/) | Windows screen companion advertises voice interaction, screen understanding, and arrows, circles, and highlights. The fetched homepage also advertises autonomous capabilities. | Advertises fully offline Ollama support. Complete offline screen understanding, voice, guidance quality, and telemetry behavior were not independently verified. As inspected on October 9, 2026, the [public release repository](https://github.com/Martinhaleluja/metis-releases) is a releases repository, not a reviewed application source codebase. |
| [ScreenDone](https://screendone.com/) | Browser-based live screen assistance: the user shares a screen, asks a question, and receives spoken step-by-step guidance while retaining control of clicks. | Its [security page](https://screendone.com/security) explicitly says shared screen and audio are processed by Google Gemini. This is cloud inference. |
| [Copilot Vision](https://support.microsoft.com/en-au/microsoft-copilot/using-copilot-vision-with-microsoft-copilot) | Screen-aware explanations, step-by-step guidance, and possible visual highlights; does not click or type for the user. | The inspected documentation did not establish a fully offline guidance mode. Do not turn this absence into a claim about every Copilot feature. |
| [UI-TARS Desktop](https://github.com/bytedance/UI-TARS-desktop) | Open-source GUI agent interpreting screenshots and operating mouse/keyboard. A candidate technical foundation, rather than the same teaching product. | Local inference is possible with a suitable deployment. However, its [quick start](https://github.com/bytedance/UI-TARS-desktop/blob/main/docs/quick-start.md) calls hosted model endpoints under the local-operator workflow. The [older archived deployment guide](https://github.com/bytedance/UI-TARS-desktop/blob/main/docs/archive-1.0/deployment.md) describes local vLLM deployment; consult current model/runtime documentation before implementation. |

## Source caveats

These findings come from first-party pages and documentation, not hands-on acceptance tests.

- GuideLayer's marketed experience closely overlaps the proposed interaction, including teaching and saved tutorials. Describing the idea as a new category would overstate novelty.
- Metis advertises the important combination of guidance and local models. Its offline capability is a vendor claim pending verification. Check that claim before asserting offline screen guidance is unique.
- The indexed [ScreenDone comparison page](https://screendone.com/compare/vs-hellotech) claimed automatic blurring. The inspected homepage and security page instead say to stop sharing before entering sensitive information; the security page says there is no automatic sensitive-data detection and describes retained session metadata/transcripts. Prefer that explicit security description when assessing privacy.
- UI-TARS uses the term local operator for controlling the user's computer. That label alone does not establish that the inference endpoint is on the same machine. Archived deployment instructions are evidence of an approach, not a validated current installation recipe.

## Product implications

The earlier recommendation in [HANDOFF.md](HANDOFF.md) understated existing competition. The inspected vendors advertise screen guidance; this investigation does not establish fully offline behavior as a unique advantage.

A proposed direction is help that teaches a repeatable task: guide the first attempt, let the person repeat it, and provide less help as they learn. This overlaps GuideLayer's positioning. It is a hypothesis to evaluate through demonstrably offline execution and an experience suited to the target user, not a confirmed market gap.

For a small prototype, investigate screen/control detection, next-step explanations, an overlay, and verification after user actions. Autonomous clicking is not required for the guidance concept. A possible scope is one desktop platform and a few local workflows, subject to measured model performance.

## Next decisive check

Benchmark the hardest local capability on the intended demo machine before committing to a broad product build:

1. Identify the correct control from a real app screen.
2. Produce a correct, understandable next step.
3. Locate that control well enough to highlight it accurately.
4. Recognize completion or a wrong turn after the user acts.
5. Measure response latency and repeat the checks with the network disconnected.

This is a proposed evaluation, not a completed benchmark. No model, runtime, platform, or hardware budget has been selected. No competitor was installed or tested. Accuracy, latency, compatibility, and differentiation remain unresolved.

## Research access

Used agent-reach's health check and Jina Reader for first-party page extraction, plus public web search and official repository documentation. Native Reddit/X search access was not available. No credentials were read, software installed, messages sent, or accounts created for this investigation.
