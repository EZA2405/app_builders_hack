# AI hackathon winners and standalone local AI opportunities

**Updated direction:** the user rejected the phone-oriented shortlist below. See [Laptop app opportunities and Laya/Jev research](LAPTOP_AI_OPPORTUNITIES.md) for the current recommendations. Winner verification and brief/transcript references here remain useful historical research.

Research question: which past AI hackathon winners and repeated consumer problems suggest a compelling app that needs neither cloud services nor documents from other apps?

The participant brief awards 25% each to usefulness and local AI, 20% to execution, and 15% each to innovation and demo quality. The user’s dependency constraints are stricter than the brief, which permits secondary cloud services. Source: [participant briefing](AppBuildersPH%20Hackathon%202026%20Participant%20Briefing.pdf), pages 5–9 and 14; previous context: [handoff](HANDOFF.md).

Researched 2026-10-09. Award status comes from organizer announcements, not a creator merely entering an event. Local execution below is documented by organizers, creators, or source inspection; these projects were not installed or benchmarked.

## Selection grounded in the briefing and kickoff transcript

The brief and transcript are the selection authority; previous winners supply precedents, not a substitute rubric. Read the [participant briefing](AppBuildersPH%20Hackathon%202026%20Participant%20Briefing.pdf) alongside the [kickoff transcript](transcript). Timestamps below refer to the supplied recording transcript.

- **12:03–13:14; briefing pages 7–8:** the product must remain useful when the cloud disappears, solve a real problem and demonstrate why local execution improves this particular experience. A local chatbot added to an otherwise cloud-dependent workflow does not meet our selection bar.
- **19:31–20:25; page 14:** problem/usefulness is 25%, local AI 25%, technical execution 20%, innovation 15%, product/demo quality 15%. Prioritize clear user value, meaningful local computation and reliable delivery. These are qualitative assessments below; no invented judge scores or measured accuracy are implied.
- **20:34–20:42:** the organizer explicitly allows teams with the same idea to succeed through execution. Competition matters when choosing a compelling implementation; it does not disqualify a concept or require an entirely new category. The room guide remains viable despite existing competitors.
- **14:21–15:47; pages 9 and 22:** substantially build the product during this hackathon; existing open-source models/libraries are allowed with disclosure. Borrow patterns from winners, not an already completed project. A small model or conventional ML model can count; an LLM is not required (44:30).
- **21:02–21:37 and 45:43–45:57; page 15:** finalists have five minutes for a live pitch/demo and three minutes for Q&A. The recorded submission video does not replace the live demonstration. Prefer one visible, repeatable end-to-end interaction that leaves time to demonstrate recovery from a wrong turn.
- **22:00–25:25 and 37:23–38:25; pages 16 and 25:** the submission needs a public repo, short demo and X/LinkedIn link, plus honest local/internet/model/tool disclosures. Submission and code freeze are **10:00 AM October 10, 2026**, with no resubmission or extension. The early spoken October 29 date is inconsistent with the slides and later clarification; do not use it.
- **41:49–42:06 and 46:55–47:21:** public deployment is not required; reproducible instructions and working output matter. Do not spend the build window creating a cloud deployment the core product does not need.

The organizer permits secondary cloud services (11:36–11:44, 45:20–45:28). The user's own blocker is stricter: **no required cloud service or documents from another app**. For these concepts, all essential input must be captured within the product and all essential processing must remain available offline after setup. That restriction comes from the user, not an invented hackathon rule.

| Actual criterion | Room reset guide | Interview follow-up rehearsal | Low-setup wardrobe |
| --- | --- | --- | --- |
| Problem/usefulness — 25% | Firsthand use plus repeated difficulty starting/resuming household tasks | Repeated off-script freezing, but mock-practice benefit is contested | Repeated cataloguing burden; evidence is older |
| Meaningful local AI — 25% | Interpret private room snapshots and adapt the next action | Recognize speech and respond to the actual answer privately | Interpret garment photos; must reduce tagging/capture effort |
| Technical execution — 20% | Grounding and before/after comparison must be tested first | Turn-based speech avoids the complexity of natural interruptions | Limit capture to individual garments; avoid whole-closet recognition |
| Innovation — 15% | Existing products set a high baseline; focus on dependable guidance/resumption | Existing offline interview tools already overlap closely | Sparse catalogues and local suggestions already have competitors |
| Product/demo — 15% | Obvious physical before/after result, including interruption recovery | Demonstrable answer → contextual follow-up → focused retry | Demonstrable photo → corrected tags → outfits from actual captured items |

**Resulting recommendation:** first evaluate the room reset guide's hardest local capability. It combines a clear problem with an observable benefit and a short demo; the recommendation depends on reliable local visual grounding. Interview follow-ups are a fallback if a turn-based speech loop proves easier to execute. Wardrobe is third. None is approved for implementation, and no device/model capability has been established.

## Verified winner precedents

### Events and dates

- Gemma 4 Good Challenge: winners announced August 24, 2026. [Organizer results](https://blog.google/innovation-and-ai/technology/developers-tools/winning-entries-gemma-4-good-challenge/).
- Google Gemma 3n Impact Challenge: June 26–August 6, 2025; Google published the winners on December 10, 2025. [Competition timeline](https://www.kaggle.com/competitions/google-gemma-3n-hackathon?linkId=15427171), [organizer results](https://blog.google/innovation-and-ai/technology/developers-tools/developers-changing-lives-with-gemma-3n/).
- Google Chrome Built-in AI Challenge 2024: submissions October 1–December 3, 2024; winners announced January 13, 2025. [Organizer launch video](https://www.youtube.com/watch?v=6LOtqprIeGQ), [organizer results](https://developer.chrome.com/blog/ai-challenge-winners).
- Google Chrome Built-in AI Challenge 2025: winners announced December 5, 2025. [Organizer results](https://developer.chrome.com/blog/ai-challenge-winners-2025).

### Seven verified winners

| Project | Exact award | What it does; local evidence | Fit with the user's blockers |
| --- | --- | --- | --- |
| **Gemma Vision** | Gemma 3n: **first place + Google AI Edge Prize** | Camera assistant for blind users; organizer establishes MediaPipe on-device deployment. [Award and technical evidence](https://blog.google/innovation-and-ai/technology/developers-tools/developers-changing-lives-with-gemma-3n/). Creator describes asking a specific camera question, e.g. a menu price, using a chest-mounted phone and controller. [Creator site](https://gemmavision.com/), [source](https://github.com/TGTech06/gemma-vision). | **Pass for runtime**: camera input and local inference; initial model download/account required. Strong precedent for a precise physical-world question rather than a general assistant. Safety/navigation capability is not independently established. |
| **Vite Vere Offline** | Gemma 3n: **second place** | Organizer verifies the offline companion and local TTS. [Award](https://blog.google/innovation-and-ai/technology/developers-tools/developers-changing-lives-with-gemma-3n/). Creator repository includes room-photo analysis producing **three concrete actions**, detailed steps, and spoken instructions; Flutter + flutter_gemma. [Creator source](https://github.com/guidomarangoni/vite-vere-offline). | **Pass for runtime**: direct photo/text input. Most useful precedent for household overwhelm. Initial Hugging Face model access/download is setup, not a continuing cloud workflow. Its existing room organizer sets a baseline for differentiation and execution quality. |
| **Dream Assistant** | Gemma 3n: **Unsloth Prize** | Personalized speech assistant trained on one person's recordings to recognize speech impairments; organizer verifies fine-tuning and voice control. [Award](https://blog.google/innovation-and-ai/technology/developers-tools/developers-changing-lives-with-gemma-3n/). Creator explicitly describes on-device/offline execution. [Creator account](https://www.linkedin.com/posts/brady-ali-medina_gemma3n-unslothai-machinelearning-activity-7420260159542689792-_fLQ). | **Conditional**: voice adaptation itself fits, but individual device actions must be checked for hidden cloud integrations. Training/custom data effort makes it a weaker overnight consumer prototype. No claim here that every advertised action works offline. |
| **AAC Board AI** | Chrome 2025: **Most Helpful — Web Application** | Pictogram communication board: turns telegraphic messages into expressive sentences, changes tone, translates and speaks. Chrome local APIs and IndexedDB are described in the submission. [Award](https://developer.chrome.com/blog/ai-challenge-winners-2025), [creator submission](https://devpost.com/software/aac-board-ai), [source](https://github.com/shayc/aac-board-ai). | **Conditional**: actual implementation imports Open Board Format files. Avoid that dependency under the user's no-other-app-documents rule; a hypothetical derivative would need its own bundled/native board. Current PWA support is a later update, so do not assume all present features existed at judging. |
| **Phonaify** | Chrome 2025: **Best Multimodal AI Application — Chrome Extension** | Select a word, hear it, record your pronunciation, receive phonetic feedback. [Award](https://developer.chrome.com/blog/ai-challenge-winners-2025), [submission](https://devpost.com/software/phonaify). Source inspection confirms microphone audio goes from MediaRecorder directly to local LanguageModel audio input. [Inspected source](https://github.com/yuchenliu15/phonaify/blob/main/src/content/views/Card.tsx). | **Local AI established; current product depends on web-page text.** A native speaking-practice app could supply its own prompts. Creator reports 5–8 seconds of model initialization; this is not our measurement. Accuracy and system voice offline behavior still need testing. |
| **The Crooked Tankard** | Chrome 2024: **Most Innovative — Web Application** | Text adventure: deterministic simulation handles consequences; AI supplies descriptions, dialogue and narration. [Award](https://developer.chrome.com/blog/ai-challenge-winners), [creator submission](https://devpost.com/software/the-crooked-tankard). Implementation supports both Chrome's built-in model and GCP models. | **Conditional**: select and package the local path explicitly; do not describe the entire app as proven cloud-free. Strong design lesson: keep rules/state deterministic and give a small model bounded expressive work. Weak evidence for an urgent consumer problem. |
| **KawanIsyarat** | Gemma 4 Good: **Cactus Prize** | Offline two-way BISINDO/spoken-Indonesian communication on Android. Organizer establishes local Gemma 4 E2B via Cactus and dynamically loaded/unloaded Whisper speech recognition. [Organizer award and architecture](https://blog.google/innovation-and-ai/technology/developers-tools/winning-entries-gemma-4-good-challenge/). An indexed organizer X post congratulates the win. [X post](https://x.com/googlegemma/status/2098069477019791773), [accessible mirror](https://www.techtwitter.com/tweet/1ffa4450-22be-4e2c-b4d0-f65f97cf2d14). | **Pass for described runtime**: camera/microphone directly, no external app data. Strong multimodal precedent; do not assume general sign-language fluency, clinical accuracy, or independently measured speed. |

### Additional cautionary winners

**OOtira — GDG China Gemma 4 Hackathon 2026 Multimodal Track Winner.** Organizer confirms the award and on-device vision in the project title. [Organizer results](https://hackathon.googdg.cn/?lang=en). A similarly named product page includes photo-based closet capture but also shopping-page extraction, order screenshots, weather, and calendar context. [Product page](https://style.ootira.com/). Its relationship to the winning team was not established. The organizer title establishes a precedent, **not proof of an entirely offline product**; the product page illustrates integrations to avoid. A fresh camera-only outfit comparison could avoid these integrations but remains a new proposal.

**Mochi — Chrome 2024 Best Real-World App, Chrome Extension.** [Organizer](https://developer.chrome.com/blog/ai-challenge-winners), [creator submission](https://devpost.com/software/mochi-6i7vuk). Uses built-in Gemini Nano for reading accessibility, but requires outside web content so it does not establish a self-contained input workflow.

**LENTERA — Gemma 3n Ollama Prize.** An offline microserver shares Gemma 3n over a local Wi-Fi hotspot. [Award](https://blog.google/innovation-and-ai/technology/developers-tools/developers-changing-lives-with-gemma-3n/). Its repository documents a 120GB+ external educational corpus, semantic search, summaries, mindmaps and quizzes. [Creator source](https://github.com/fengkiej/lentera). Offline does not automatically satisfy the user's constraint: this workflow still depends on content imported from elsewhere. Exclude as a proposed app.

### What to borrow

These are product-design inferences, not the judges' explanation or validated market demand:

1. **A narrow interaction can serve a large audience.** Vite Vere's camera-to-room-actions workflow generalizes to everyday household overwhelm without requiring calendars or imported documents. Differentiate with one visibly grounded action, highlight the relevant area, and recheck progress from the next camera view.
2. **Capture input inside the product.** Camera, microphone, tapping and native typing avoid connectors, imports and permissions surprises.
3. **Make AI necessary to the interaction.** Gemma Vision answers a question about what is physically in front of the user; Phonaify reacts to how the user actually speaks.
4. **Keep the app's reliable state outside the model.** The Crooked Tankard separates simulation from generative flavor; AAC Board's creator abandoned unreliable sentence prediction after illogical outputs. A winning demo is not evidence that a model can be trusted with arbitrary state or judgments.

## X/Twitter access limits

Agent-reach was used through Jina Reader for first-party page extraction. The parent session established that no native Twitter/OpenCLI backend is installed, Exa's free quota is exhausted, and Jina X-domain fetching is blocked. Initial X-focused public-web searches were mostly empty. A subsequent search found a TechTwitter mirror of **@googlegemma's September 10, 2026 KawanIsyarat winner post**; Jina extracted both the displayed text and its original [X status link](https://x.com/googlegemma/status/2098069477019791773). Its award and local architecture were independently corroborated against Google's August 24 announcement. This is **indexed/mirrored X discovery, not live X timeline access**. LinkedIn creator accounts are explicitly labeled rather than presented as tweets.

## Recurring problems and ranked app opportunities

Ranking is a product judgment for this brief, not a market-size estimate or a measured benchmark. No idea has been selected. The proposed apps use direct camera/microphone/native inputs; none requires Messenger, Google Calendar, Drive/Notion files, or another app's documents. Models and offline voices must be installed before the demonstration.

### 1. A camera guide that gets you through a five-minute room reset

**Specific problem:** the user sees many possible tasks, cannot choose a starting point, then loses their place after distraction. The target extends beyond a diagnosis: overwhelmed adults, students, busy households, and people managing limited energy.

**Firsthand evidence:** a January 2025 post describes cleaning successfully by submitting a photo and following tailored instructions; the author explains that advice about a particular visible box was useful while generic cleaning manuals were not. Replies describe losing their place in a multi-step plan and using conversation mode to resume. [Actual-use report and replies](https://www.reddit.com/r/adhdwomen/comments/1hu963m/chat_gpt_made_it_possible_for_me_to_clean_i/). Independently, users in 2021 and 2026 describe being overwhelmed or standing still because they cannot choose what to clean first. [2021 complaint](https://www.reddit.com/r/CleaningTips/comments/n8my8n), [2026 complaint](https://www.reddit.com/r/CleaningTips/comments/1sm1pgv/is_anyone_else_get_stuck_not_knowing_where_to/). These are qualitative observations, not representative prevalence or purchasing evidence.

**Proposed interaction:** point the camera at one desk or countertop; choose five minutes; the app marks one visible target and speaks one action. The user makes the change and takes another view. It checks the relevant area, asks for confirmation when uncertain, and chooses the next action. A visible current-step card restores context after an interruption.

**Why local AI matters:** the model must interpret this particular room repeatedly. Private interiors need not be uploaded; repeated progress checks need no API quota or connection. A timer and fixed generic checklist alone do not establish useful AI: the action must change when the scene changes.

**Competition:** Vite Vere Offline already offers room-photo-to-three-actions and local speech. Cleo advertises scanning, plans, inventory and progress. [Vite Vere source](https://github.com/guidomarangoni/vite-vere-offline), [Cleo](https://trycleo.app/). A generic photo-to-list app is therefore weak differentiation. Even visual highlighting is already advertised elsewhere: [Limpo](https://limpo.aivoryvn.com/). This research does not establish a unique feature combination.

**Small demo:** one tabletop with a cup, paper and clothing; highlight one target, have the user move it, inspect the next view, then recover after an intentional interruption. Keep actions to putting away and grouping items. The user confirms what is rubbish or valuable; the model cannot infer that reliably from appearance.

**Decisive gate:** on the actual demo machine, identify a correct visible target, locate it accurately enough for the overlay, and recognize relevant change across repeated photos. Compare against a simple checklist. If it cannot ground its actions or the model delay breaks the flow, do not build a broad live-camera coach. Start with explicit snapshots rather than promising continuous real-time video.

**Assessment:** strongest combination of demonstrated pain, prior winning local precedent and an easy-to-understand physical demo. Competition and visual reliability are substantial risks.

### 2. Speaking rehearsal for the moment an interviewer goes off-script

**Specific problem:** a person can rehearse polished answers but freezes or rambles when the next question is unexpected. Scope the first product to behavioral interviews; do not bundle every difficult conversation.

**Firsthand evidence:** a March 2025 thread describes forgetting prepared answers; users discuss rehearsing aloud and relying on a few anchor stories. [Interview thread](https://www.reddit.com/r/interviews/comments/1j5byyf/how_do_i_stop_my_mind_from_going_blank_during_an/). In June 2026, another user specifically identifies unexpected questions as the failure point. [Unexpected-question complaint](https://www.reddit.com/r/interviews/comments/1txufy9/how_do_i_interview_with_anxiety/). A September 2026 post says notes and existing mock-interview apps have not transferred to real interviews. [Important counterevidence](https://www.reddit.com/r/interviews/comments/1wh4ly2/how_do_you_stop_scrambling_and_nerves_in/). Treat that as a reason to test the proposed mechanism, not as proof another simulator will solve it.

**Proposed interaction:** pick a built-in scenario and record a short answer. The app asks a follow-up grounded in what the user actually said, such as requesting a concrete result. After a few turns it highlights one passage that did not answer the question, explains why, and lets the user retry that segment. Time pressure and interruptions are optional controls. Do not claim to cure anxiety or predict hiring decisions.

**Why local AI matters:** recordings may include salary, personal failures or workplace conflict; users can repeat practice without uploading them. Direct microphone capture and in-app prompts work without importing a résumé, job posting, meeting recording or calendar event.

**Competition and precedent:** Phonaify proves a bounded microphone-to-local-feedback interaction can win a Chrome category. Existing fully local speech products already include interviews and follow-ups: [SpeakLocal](https://play.google.com/store/apps/details?hl=en-US&id=com.speaklocal.speaklocal), [speakloop](https://github.com/ehsankolivand/speakloop). Speakloop's documented loop is particularly close. Broad voice coaching or privacy alone is not novel.

**Small demo:** one built-in behavioral question, one follow-up based on a specific detail in the answer, timestamp-linked feedback, then a retry. Use turn-based local ASR, a local model and preinstalled local speech; benchmark the full loop before offering natural interruptions.

**Decisive gate:** verify that feedback is grounded in the actual recording, the simulated interviewer maintains its role, and the next question is coherent. Users explicitly complain that AI roleplay becomes too agreeable or lacks realistic reactions. [Roleplay criticism](https://www.reddit.com/r/managers/comments/1t55z6h/do_you_practice_difficult_conversations_like_this/). A pleasant conversation or higher in-app score is not evidence of improved real interview performance.

**Assessment:** clearest fallback when vision is unreliable; privacy and repeated use are credible advantages. Crowding and uncertain transfer to real conversations reduce confidence.

### 3. A camera-first wardrobe that helps before you catalogue everything

**Specific problem:** a useful digital wardrobe requires too much initial photography, cropping and tagging. The opportunity is reducing setup friction, not adding another generic AI stylist.

**Firsthand evidence:** a 2024 discussion includes users describing months of photography/data entry and roughly three minutes per item; one says they would start by adding items as worn instead. [Cataloguing burden](https://www.reddit.com/r/capsulewardrobe/comments/1boupup/for_those_who_indexed_their_closets_how_did_you/). A separate review describes manual background removal and categorization as an onboarding burden. [Comparative user review](https://www.reddit.com/r/femalefashionadvice/comments/n4ubfn/a_quick_review_of_every_virtual_closet_app_my/). These are older complaints: current products may have addressed parts of them. Do not use an app-branded subreddit promotional post as independent validation.

**Proposed interaction:** photograph a few separate garments inside the app, confirm automatically inferred type/color, then ask for two combinations for an occasion stated in the app. Show exactly which captured items are used. Add another item only when useful; never require a complete closet before the first result.

**Why local AI matters:** garment and mirror photos stay private, local vision can propose tags, and recommendations work offline from the app's own records. Enter occasion and temperature manually. Exclude live weather, shopping sites, receipt imports, social feeds and cross-app photo-library dependencies from the core.

**Competition:** the GDG China 2026 event lists OOtira as its Multimodal track winner with on-device vision in its title. [Organizer results](https://hackathon.googdg.cn/?lang=en). That establishes the award and positioning, not a verified fully offline runtime. A similarly named OOtira product page advertises weather/shopping integrations and usefulness with five captured items, but the relationship to the winning team was not established. [Product page](https://style.ootira.com/). ClosetCue also advertises offline outfit suggestions. [First-party product description](https://orangeforgeai.com/closetcue.html). The sparse-closet approach is therefore not an established market gap.

**Small demo:** capture five garments directly, correct one wrong tag, then obtain two combinations with short explanations. Show the actual cutouts; do not add virtual try-on or imply a model sees occluded items in a closed closet.

**Decisive gate:** measure time and corrections needed per captured item. If it does not beat manual entry, the AI misses the main pain. Single-garment segmentation is already common; a pan-over-the-entire-closet scanner would need substantially harder detection/deduplication tests.

**Assessment:** fits all dependency constraints and has repeated setup-friction evidence. Third priority because competition is dense and the minimal version has less distinctive local AI value.

## Dependencies and recommendation

| Proposed app | Required input generated inside app | Local AI work | Core external dependencies |
| --- | --- | --- | --- |
| Room reset guide | Camera snapshots; user confirmations | Scene interpretation, grounded next action, progress comparison | None after models/voices are installed |
| Interview follow-up rehearsal | Microphone answer; built-in scenario; optional native text | ASR, contextual follow-up and evidence-linked feedback | None after models/voices are installed |
| Low-setup wardrobe | Direct garment photos; occasion/temperature text | Vision tagging/segmentation and recommendation reasoning | None after models are installed |

A downloaded model or voice pack is a setup requirement; a cloud API called for every useful action is a runtime dependency. Test from a cold application start with networking disabled, after provisioning, so hidden login, browser-model initialization, telemetry gates or online speech services cannot be mistaken for an offline workflow. No framework/model choice or device capability is assumed proven here.

**Recommendation:** evaluate the room-reset interaction first. It has the best link between actual use, recurring complaints, a verified winning precedent and a visible demo. Select it only if local grounding/progress checks work; otherwise evaluate turn-based interview follow-ups. Keep wardrobe as a lower-priority option. Before committing to any concept, compare the proposed interaction with its simplest existing workaround.

The existing screen guide remains eligible when limited to local app operations and no imported documents, but prior research establishes close competitors and unresolved control-localization/latency. This investigation does not overturn those findings. See [screen guide research](SCREEN_GUIDE_RESEARCH.md).

Excluded patterns: chat/calendar assistants, cloud meeting bots, Drive/Notion RAG, imported-PDF tutors, messenger scam analyzers and cloud-bank/email agents. Generic dictation, flashcards, screenshot search, trip albums and the earlier very narrow hobby tools were not recycled as recommendations.

## Evidence quality and unfinished validation

Winner status was checked against organizer results. Product functionality and offline claims come from first-party descriptions/source inspection, not hands-on testing. Social posts show individual experiences and counterexamples; they do not establish prevalence, willingness to pay or intervention efficacy. Crossposts from the same author are not independent evidence. Exact vote totals change and are not used as market-size estimates.

No app, model or competitor was installed; no latency, accuracy, memory, battery or consumer study was run. Feasibility gates above are proposed work. This is research material, not a selected product or an architecture decision.
