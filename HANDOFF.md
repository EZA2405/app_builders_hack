# AppBuilders local AI idea research handoff

## Objective and current status

Continue finding a compelling consumer app idea for the AppBuildersPH Local AI hackathon, grounded in firsthand Reddit/X problems and the kickoff brief. No idea has been selected or approved. No implementation, model benchmarking, publishing, or outreach has occurred. The user most recently requested this handoff file.

The user wants broadly relatable demand, a specific problem, a memorable wow interaction, and a convincing reason for local inference. The central lesson: specificity of the problem does not require a tiny audience. The assistant initially missed the kickoff material and produced two poorly calibrated shortlists. Read the source material before continuing.

## Authoritative source artifacts

Workspace: `.`

- Kickoff transcript: `./transcript`
- Slides: `./AppBuildersPH Hackathon 2026 Participant Briefing.pdf`

Both were read in the last research turn. Refer to these for the full challenge, rules, judging weights, deadlines, and submission requirements rather than treating this handoff as a replacement specification. Useful transcript timestamps: 10:21-16:44 theme/challenge/rules; 19:31-21:37 judging and live pitch; 22:00-25:25 submission; 37:23-38:25 code freeze; 44:16-47:21 format clarifications. The transcript contains an early mistaken date; the slides and later transcript identify October 9 build day and October 10 deadline. `pdftotext -layout 'AppBuildersPH Hackathon 2026 Participant Briefing.pdf' -` works locally.

Selection implication from the brief: optimize useful, fundamental local inference plus reliable execution, with innovation and product polish. A visible offline demonstration is more persuasive than a privacy slogan. The host accepts overlapping ideas when execution is strong. Any suggested build scope or demo below is the assistant's hypothesis, not measured capability.

## User feedback and rejected directions

Initial request: use agent-reach to explore Reddit and Twitter for local AI consumer app options.

First shortlist: writer dictation, screenshot search, source-backed flashcards, comic translation, searchable lectures. User rejected these as generic, insufficiently niche, and lacking wow, asking for clear problems people want fixed.

Second shortlist: cross-stitch error detection, last-sentence recovery, sewing pattern checks, left-handed knitting conversion, accessible appliance reading. User then rejected these as WAY too niche and told the assistant to read the kickoff transcript.

Interpret the combined feedback as mainstream or substantial consumer appeal with a sharp problem and a surprising interaction. Do not return either rejected shortlist with cosmetic renaming. These are rejected directions, not permanent bans on their underlying technologies.

## Latest shortlist: presented, NOT user-approved

### 1. Screen-aware, patient computer guide

Assistant's strongest recommendation after reading the brief. User speaks a goal; local inference examines the actual screen; an overlay points to the next control, explains one step, and verifies progress after the user clicks. Initial scope proposed: one desktop platform, three local tasks, guidance rather than autonomous clicks.

Proposed offline demo: resize a photo and save a smaller copy, adapting when the user opens the wrong menu. Broad problem: exhausting family tech support where helpers cannot see or understand the parent's current screen.

Evidence:
- https://www.reddit.com/r/AgingParents/comments/1fzeqx5 — parent cannot describe screen; sending email takes 20 minutes.
- https://www.reddit.com/r/AgingParents/comments/1lsy4m9/im_losing_my_mind_being_their_247_tech_support_is/ — explicit request for better tech support, possibly AI.

Competition: Gemini Live already supports screen assistance: https://support.google.com/gemini/answer/15274899?hl=en-GB . Differentiate through accurate step guidance and verified offline operation. Major uncertainty: control localization, model latency, and adapting reliably. None tested.

### 2. Protected screen output

Locally process one captured window into a separate audience-facing presentation window, hiding selected sensitive content. Proposed demo: raw and protected outputs side by side. Broad problem: accidental disclosure during presentations, tutorials, and screen recording.

Evidence:
- https://www.reddit.com/r/careeradvice/comments/1tk6aye/help_accidentally_shared_screen_in_meeting/
- https://www.reddit.com/r/MicrosoftTeams/comments/1r145q4/how_can_i_blur_parts_of_my_screenshare_during_a/

Competition includes browser masking extensions. Cross-application processing is a candidate distinction, not an established empty market. Major risk: unmasked frames leaking before processing; a prototype cannot claim perfect protection. Screen recording can work offline; a remote meeting still needs connectivity. Do not conflate these.

### 3. Explain the manipulation in a suspected scam conversation

Import message screenshots, reconstruct sequence, highlight trust-building, urgency, secrecy, and payment requests with evidence from the conversation. Target problem is persuading a family member who believes the message, not merely producing a generic scam score.

Evidence: https://www.reddit.com/r/Scams/comments/1t2aey3/my_dad_is_in_a_relationship_over_whatsapp_and_i/ — poster explicitly wants evidence to convince their father.

Local advantage: intimate conversations and financial details remain private. Proposed scope: screenshot import and evidence-linked warning signs. Cannot verify sender identity, certify safety, or make reliable deepfake claims. Competition and feasibility not assessed.

### 4. Turn a trip folder into an editable memory album

Group moments, choose representative photos, construct a short album, explain selections, allow replacements, preserve originals. Target pain: photo selection/editing backlog prevents making photo books or small sharing collections.

Evidence: https://www.reddit.com/r/AskPhotography/comments/1w7gm9i/how_do_you_keep_the_editing_process_fast_and_fun/ — recent firsthand account of photos postponed for months or years and explicit desired outputs.

Local advantage: no bulk personal-library upload. Suggested scope: photos only, one album format. Assistant rated differentiation weaker than first two. No testing or competition audit.

## Research access and evidence quality

The agent-reach skill was explicitly requested and read at `agent-reach/SKILL.md in the installed skills directory`, along with `references/social.md` and `references/search.md`.

Health check: `agent-reach doctor --json` found no installed native Reddit backend and no Twitter CLI. Exa via mcporter was configured but initially unverified. A read-only Exa search succeeded; a subsequent X query hit the free MCP rate limit. Continued via public web search. Native platform search/full live social access was NOT established. No credentials were read, no login was automated, and no software was installed.

Working Exa invocation before rate limit: `mcporter call exa.web_search_exa query='...' numResults=8`. Do not repeat unlimited retries when rate-limited.

Web search found substantial Reddit content, but X searches repeatedly returned little or no relevant firsthand evidence. Do not imply balanced Reddit/X coverage. One indexed X post discussed offline phone AI, but it was promotional awareness, not validated consumer demand.

Many Reddit results were developer promotions. Distinguish these from firsthand complaints, explicit requests, and user replies. Upvotes are attention, not purchase intent. Product privacy/performance claims are untested. Earlier searches showed automatic offline music page turning already advertised by https://sheetscroll.com/ ; this was deprioritized.

`agent-reach check-update` reported v1.5.0 current during this session. No update performed.

## Next useful work

1. Read the kickoff sources, then maintain the corrected selection bar above.
2. Continue research or critically assess the latest shortlist. The user has not chosen a concept; do not begin building based solely on the assistant's ranking.
3. Seek concrete workflow descriptions, repeated complaints, current workarounds, and requested outcomes across substantial consumer audiences. Prefer fewer strong candidates to another long speculative list.
4. For each serious candidate, distinguish verified pain, existing alternatives, the proposed new interaction, why local inference matters, and the smallest demonstrable scope.
5. Before asserting a concept can be built overnight, benchmark the hardest local capability on available hardware. Hardware budget and team preferences remain unspecified.

## Suggested skills

Call the Skill tool for these if available; otherwise locate their SKILL.md in the next agent's local installation. Installation references below are descriptive, not repository file paths.

- `agent-reach`: required for continued internet/platform research; follow its health check, backend announcement, and reference routing.
- `pdf:pdf`: consult when inspecting the participant briefing PDF; local skill path `pdf/SKILL.md in the installed PDF plugin`.
- `research`: useful if the user wants a durable cited research document in the workspace; do not create one merely to satisfy agent-reach, whose temporary outputs belong outside the workspace.
- `handoff`: use if asked to refresh this transfer document. Path `handoff/SKILL.md in the installed skills directory`.

## Working instructions carried from the session

Ponytail full mode is active: smallest complete work, plain concise communication, conclude with skipped checks and material risks. Preserve unrelated files. Use `rg` for source discovery. There was no project engineering-skills index among the discovered workspace files; recheck current state if coding begins.

The user's provided AGENTS instructions require independent Claude review for review requests or finished diffs, with read-only execution and verified findings. The research session had no implementation diff.

The original research request did not authorize posting, messaging, submissions, deployment, or vault writes. The subsequent user instruction explicitly authorizes creating a public repository, committing and pushing this material, and inviting `itsalexi` as a collaborator. No secrets or personal source identities are included in this handoff.
