# Measured results

Every number here was measured on the dev machine: Apple M4, 16 GB, macOS 26.6. Nothing is estimated. Fake benchmarks are grounds for disqualification, so add a row only after you've run it, and include the command.

## Task
Given a non-technical user's goal and the app's real command list (menu tree + toolbar, read via macOS accessibility), pick the command that accomplishes it.

**Held-out test set:** Preview (10 goals), Finder (8), System Settings (8), Safari (9) = **35 goals**. These apps are **never** used for training. Answer keys were written before running any model. Fixtures: `ml/fixtures/*_real.json`.

## Results

| Model | Where it runs | Setup | Accuracy | Median latency | Date |
|---|---|---|---|---|---|
| Apple Foundation Model (on-device ~3B) | Local | Hand-typed Preview menu (~60 cmds), full list, guided generation | 4/10 | ~5–8 s | 2026-10-09 |
| Apple Foundation Model + NLEmbedding shortlist | Local | Same, rewrite → shortlist → constrained pick | 5/10 | ~4 s | 2026-10-09 |
| TypeSafe **Jev** (`jev-latest`), hosted | **Cloud (comparison only)** | Real menus, 4 held-out apps, 200-wide tournament | **35/35** | 0.35–1.6 s per app | 2026-10-09 |
| OpenAI **Decisions API** (`gpt-6-luna`), hosted | **Cloud (comparison only)** | Same fixtures and wording, 200-wide tournament | **33/35** | 0.38–1.01 s per app (median per decision) | 2026-10-10 |
| Laya (base, 421M) | Local-capable (measured on Colab T4 and M4) | Real menus, 16-wide tournament | 8/35 | ~0.66 s (T4), ~1.9 s (M4) | 2026-10-09 |
| **Laya fine-tuned v1** (teacher data, 3 epochs) | Local-capable (trained + measured on Colab T4) | Same | **25/35** | ~0.65 s (T4) | 2026-10-09 |
| **Laya fine-tuned v3** (12,284 rows: 39 apps, traps, paraphrases, mined hard negatives, 19 websites; hard labels, 3 epochs) | Local-capable (trained + measured on Colab T4) | Same | **26/35** | 0.55–1.08 s (T4) | 2026-10-09 |
| **Laya fine-tuned v4e5** (v3 data + 422 mined rows from the newer apps; **5 epochs**) | Local-capable (trained + measured on Modal H100) | Same | **29/35** | 16 min training (H100) | 2026-10-09 |
| **Laya fine-tuned v1**, same checkpoint on the Mac | **Local (Apple M4, MPS)** | Same | **25/35** (reproduced) | 1.2–2.2 s (≈15 sequential calls per decision) | 2026-10-09 |
| Qwen3.5-4B via local-jev | Local | Real menus | _pending_ | | |

**Per-app breakdown for Laya fine-tuned v1** (base in parentheses):
- Preview 6/10 (1)
- Finder 8/8 (3)
- System Settings 5/8 (1)
- Safari 6/9 (3)

**Arguable misses.** These are not counted, and the official score stays 25/35:
- Safari "make the words on this page bigger" → `View > Make Text Bigger`
- "clear my browsing history" → `Safari > Clear History…`

The keys only list Zoom In and History > Clear History….

**Fine-tune v1 validation** (371 rows, 4 unseen apps, single 16-way choice):

| | Before | After |
|---|---|---|
| Accuracy | 0.350 | **0.806** |
| ECE | 0.494 | **0.076** |

Training was on Colab: T4, 3 epochs, micro-batch 8 × grad-accum 8, `--shuffle-options --label-smoothing 0.05 --seed 7`; notebook `ml/finetune_colab.ipynb`. A full fine-tune didn't fit in a 16 GB M4's GPU memory: MPS ran out of memory at an 8.9 GB cap.

**Per-app breakdown for hosted Jev:**
- Preview 10/10 (0.57 s)
- Finder 8/8 (0.35 s)
- System Settings 8/8 (0.37 s)
- Safari 9/9 (1.60 s; 256 cmds exceed the 255-choice cap, so it uses a tournament)

**Notes:**
- Finder's first run scored 7/8 because the answer key said `Empty Trash…` but the real item is `Empty Trash`. The key was fixed and the rerun scored 8/8.
- Low confidence lines up with vague goals: "find a document" 0.44, "clear history" 0.44, "where was this taken" 0.50.

**Reproduce:**
```bash
cd ml
python3 bench_localjev.py --url https://api.typesafe.ai --model jev-latest --fixture fixtures/preview_real.json   # needs JEV_API_KEY in ml/.env
python3 bench_localjev.py --url http://127.0.0.1:8766 --model convaiinnovations/laya --group 16 --fixture fixtures/preview_real.json
```

## Held-out web journeys (45 steps, never trained on)
Sites: YouTube, Wikipedia, Shopee and PhilHealth. PhilHealth includes 8 second-page steps that use "Already done". Fixtures are in `fixtures/web_test/`, written before any model ran. The steps use a 16-wide tournament over page elements, each written as `role "name" · context`.

| Model | YouTube | Wikipedia | Shopee | PhilHealth | **Total** | Latency (M4) |
|---|---|---|---|---|---|---|
| Laya base | 2/10 | 4/10 | 3/10 | 3/15 | **12/45** | 0.4–3.3 s |
| Laya v1 (menus only, no web training) | 7/10 | 6/10 | 6/10 | 6/15 | **25/45** | 0.4–5.7 s (slowest on 400-element pages) |
| **Laya v3** (with web journeys) | 8/10 | 8/10 | 6/10 | 7/15 | **29/45** | 0.2–1.4 s (T4) |

Reproduce: `for f in fixtures/web_test/*.json; do python3 bench_localjev.py --url http://127.0.0.1:8766 --model guide-v1 --group 16 --fixture $f; done`

## Full-tournament validation (model selection)
127 goals across 4 apps never trained on (`fixtures/val/`). **v1: 79/127 (62.2%). v3: 95/127 (74.8%). v4e5: 98/127 (77.2%)**; web held-out v4e5 28/45. v3 per app:
- Activity Monitor 22/30
- Disk Utility 29/35
- Numbers 20/31
- Terminal 24/31

v3 single 16-way validation (492 rows): 0.386 → **0.852**, ECE 0.444 → 0.074; trained in 46.1 min on a T4.

v3 per-app held-out (v1 in parentheses):
- Preview 7/10 (6)
- Finder 8/8 (8)
- System Settings 6/8 (5)
- Safari 5/9 (6)

This was the only v3 held-out run. On its own training goals under the same tournament, v1 gets 708/909 (77.9%). The tournament loses right answers in early rounds.

## v6 (2026-10-10): two candidates, chosen by validation
Data: `data/v6/train.jsonl`, 28,250 rows. It contains:
- v5 rows soft-labelled (0.7 teacher + 0.3 Jev)
- Jev-labelled app and web goals
- routing, obvious-route and dialog-step rows
- mined hard negatives
- rows whose goal phrasing matched a test goal, removed

Both candidates trained 5 epochs with head budget 320 on a Modal H100 (~41 min). The script `ml/modal_train.py` evaluates every candidate on all sets; every run is reported here.

| | Validation (127) | Held-out apps (35) | Held-out web (45) | Risk check: caught / false alarms | Routing (162) |
|---|---|---|---|---|---|
| v4e5 (previous) | 98 | 29 | 28 | — | 65 |
| **v6en** (English Laya base) | **100** | 29 | **32** | 13/14, 0/16 (any threshold 0.3–0.7) | **97** |
| v6ml (multilingual Laya base) | 91 | 23 | 29 | 14/14, 0/16 (threshold ≤ 0.5) | 85 |

**Choice: v6en** (best validation). It is now served as `guide`. The same checkpoint on the Mac (M4, MPS) reproduces Preview 7/10, with a median of 2.1 s per decision.

Per app, v6en:
- Validation: Activity Monitor 23/30, Disk Utility 27/35, Numbers 23/31, Terminal 27/31.
- Held-out: Finder 8/8, Preview 7/10, Safari 8/9, System Settings 6/8.
- Web: PhilHealth 7/15, Shopee 8/10, Wikipedia 9/10, YouTube 8/10.

Logs: `train-v6en.log` and `results-v6en.txt` on the `gabay-models` Modal volume. Reproduce: `modal run ml/modal_train.py --version v6en --data data/v6/train.jsonl --epochs 5 --head 320` (add `--base multilingual` for v6ml).

## v7 (2026-10-10): contrast rows for live-test failures (not chosen)
Data: `data/v7/train.jsonl`, 29,776 rows = v6 (28,250) + 1,526 new rows from `contrast_data.py`. All new goals are Claude-written, on training apps only. About 20% are Taglish.
- **File vs view** (60 goals): "make this video small enough to send" → `File > Export As > 480p…`, with `View > Zoom Out` as a decoy. Jev agreed with the label on 53/60.
- **View vs file** (47 goals): the reverse direction, so "smaller" doesn't always mean Export. Jev agreed on 44/47.
- **Look-alike words** (175 goals): the goal's words appear in a wrong command. Jev agreed on 168/175.
- **System jobs → System Settings** (80 goals × 3 training apps in front): camera/mic permission, Wi-Fi, Bluetooth, sound output, screen-wide text size, updates, printers, storage and similar. Look-alike apps are decoys. Jev agreed on 208/240 and confidently disagreed (>0.85) on 2, which were dropped.
- **Stay in the app** (51 goals × 2): in-app goals that use system words, e.g. "make this word bigger" in TextEdit. Jev agreed on 97/102.

Menu rows are repeated ×3 and routing rows ×2, each copy with a fresh option group. Any goal that nearly copies a test, validation or use-case goal (≥50% content-word overlap) is skipped.

- **Caveat:** the routing eval's 8 System Settings goals now share topics with training (Wi-Fi, Bluetooth, text size, update, printer, sound). The wording is different, but that slice is no longer independent.
- Reproduce: `python3 contrast_data.py data/v7`, then `modal run ml/modal_train.py --version v7en --data data/v7/train.jsonl --epochs 5 --head 320`.

v7en (English Laya base) trained 5 epochs with head budget 320 on a Modal H100 (37 min). `modal_train.py` scores every set on every run, so this is v7en's one held-out run:

| | Validation (127) | Held-out apps (35) | Held-out web (45) | Risk check: caught / false alarms | Routing (162) |
|---|---|---|---|---|---|
| v6en (current `guide`) | **100** | 29 | 32 | 13/14, 0/16 | **97** |
| v7en | 98 | 28 | 32 | 13/14, 0/16 (any threshold 0.3–0.7) | 84 |

**Choice: v6en stays.** v7en is lower on validation (98 vs 100). Routing also dropped (84 vs 97), even though v7 added routing rows. `routing_eval.py` prints only a total, so the cause isn't measured yet.

Per app, v7en:
- Validation: Activity Monitor 21/30, Disk Utility 29/35, Numbers 23/31, Terminal 25/31.
- Held-out: Finder 8/8, Preview 8/10, Safari 5/9, System Settings 7/8.
- Web: PhilHealth 6/15, Shopee 9/10, Wikipedia 9/10, YouTube 8/10.

Logs: `train-v7en.log` and `results-v7en.txt` on the `gabay-models` Modal volume.

## v8 (2026-10-10): text size vs zoom, and window controls mixed with menus (not chosen)
Data: `data/v8/train.jsonl`, 29,012 rows = v6 (28,250) + 762 new rows from `toolbar_data.py`. It starts from v6, not v7, because v7 lost on validation. All new goals are Claude-written, on training apps only. 20% are Taglish. Rows are repeated ×3, each copy with a fresh option group. The near-copy guard skipped 15 goals that overlapped a test, validation or use-case goal (e.g. "make the words in this note bigger" ~ "make the words bigger").
- **Text size vs zoom vs picture size** (196 goals, 12 training apps). This targets the live failure where Preview offered `View > Zoom In` for a text box's font size.
  - "the words in my letter are too small, make them bigger" → `Format > Font > Bigger`.
  - "magnify the view, but don't change the size of the words in my letter" → `View > Zoom In`.
  - "make the pictures in my note smaller" → `View > Attachment View > Set All to Small`.
  - Every goal's decoys come from the other two families.
  - Jev agreed with the label on 106/108 font goals, 51/53 zoom goals and 34/35 picture goals. None were dropped.
- **Window controls mixed with menus** (59 goals, 7 windows): option groups mix menu commands with an open window's checkboxes and buttons. They are keyed like `Planner.key` (`checkbox "Use Large Labels" · Settings`), the way the first step sees them with `step1Controls` on.
  - A control is the answer in 24 goals. Jev agreed on 21 and confidently disagreed on 1, which was dropped.
  - A menu command beats look-alike controls in 35 goals. Jev agreed on all 35.
  - **Caveat:** the main-window dumps (`/tmp/sg/train*`) are menus-only, so there are no document toolbars like Preview's "Aa". These are the Settings and Find windows that `harvest_dialogs.py` read from training apps. Save, Print and Export panels are left out, because at runtime they are dialogs and never mixed with menus.
- Reproduce: `python3 toolbar_data.py data/v8`, then `modal run ml/modal_train.py --version v8en --data data/v8/train.jsonl --epochs 5 --head 320`.

v8en (English Laya base) trained 5 epochs with head budget 320 on a Modal H100 (35 min). This is v8en's one held-out run:

| | Validation (127) | Held-out apps (35) | Held-out web (45) | Risk check: caught / false alarms | Routing (162) |
|---|---|---|---|---|---|
| v6en (current `guide`) | **100** | **29** | 32 | 13/14, 0/16 (any threshold 0.3–0.7) | **97** |
| v8en | 95 | 28 | 32 | 14/14 at threshold 0.3–0.5, 13/14 at 0.6–0.7; 0/16 at all | 88 |

**Choice: v6en stays (VAL 95 < 100).** v7 (+1,526 rows) and v8 (+762 rows) both scored below v6en on validation.

Per app, v8en:
- Validation: Activity Monitor 20/30, Disk Utility 27/35, Numbers 22/31, Terminal 26/31.
- Held-out: Finder 8/8, Preview 8/10, Safari 7/9, System Settings 5/8.
- Web: PhilHealth 7/15, Shopee 8/10, Wikipedia 9/10, YouTube 8/10.

The local Modal client lost its network connection as training finished. The remote run still completed every benchmark: `results-v8en.txt` ends with the baselines line. The app then stopped before zipping, so the checkpoint is only unzipped at `models/laya-guide-v8en` on the `gabay-models` volume. Logs: `train-v8en.log` and `results-v8en.txt` on the same volume.

## Real use cases, first step on this Mac (dev set, 2026-10-10)
**What it is:** 41 requests taken from `docs/research/USER_TASKS.md` (`ml/usecases/scenarios.py`), with acceptable answers written before any run. It runs Gabay's real decision path (`--plan`: read the screen, stay or route, pick) on the live apps.
- **Not a benchmark.** The settings routing below was developed while looking at these results.
- Some requests are in Finder and System Settings, which are held-out apps, but these are new requests, not the test set.

| Start | Before | After |
|---|---|---|
| Finder (system tasks should go to System Settings) | 1/14 | **12/14** |
| System Settings (right sidebar pane) | 8/12 | **12/12** |
| Risk check (4 scams, 3 look-alikes) | 7/7 | 7/7 |

- **Before:** the picker matched look-alike words in the app in front ("update my computer" → Finder `Go > Computer` at 0.88). App routing only ran when that pick was below 0.35.
- **After:** Apple's on-device model reads only the request text (no screen data) and answers two things: is this a System Settings job, and which pane.
  - Settings jobs go to System Settings in the Dock, then to the pane's sidebar row. Laya picks everything else, including the steps inside the pane.
  - Decoding is greedy: two runs gave identical routes.
- **Separate check, 27 requests (12 settings, 15 not):**
  - The fine-tuned Laya, asked a yes/no "settings?" question, caught 5/12 settings requests with 1/15 false alarms (threshold 0.5). Base Laya caught 2/12.
  - Apple's model caught 12/12, with 2/15 false alarms ("make this word bold", "play my music").
- Mail wasn't scored: an account password dialog was open, so every pick (correctly) stayed in that dialog.

Reproduce: `open -W -n app/build/ScreenGuide.app --args --plan Finder goals.json out.json` (one file per start app, goals from `scenarios.py`).

**Update (2026-10-10, later):** inside apps the routing misfired: "make the words bigger" in TextEdit went to System Settings > Displays. Two causes:
- an Apple-model route-memory feature matched the System Settings Dock icon on step 1;
- the settings check didn't look at the in-app pick.

Fixes:
- Inside a non-desktop app, a confident in-app pick (≥ 0.6) wins.
- Route memory never matches the Dock.
- Telling Apple's model which app is in front was tried and reverted: Finder fell to 6/14.

Two harness bugs were also found:
- Background apps report most menu items as disabled, so `--plan` now brings the app to the front first.
- The earlier "after" numbers were measured before that fix.

Results with `ml/usecases/run.sh` (added TextEdit, Preview and Music "stay in the app" sets, answers written before running):

| Start | Score |
|---|---|
| Finder | 13/14 |
| System Settings | 12/12 |
| TextEdit | 9/9 |
| Preview | 5/6 |
| Music | 3/3 |
| Risk check | 7/7 |
| Mail | 1/8 (an account password dialog is open on this Mac; every pick correctly stays in that dialog, so Mail isn't scored) |

**Update 2 (2026-10-10):** the ≥ 0.6 in-app gate turned out to be noisy. Replaying a recorded live session (`--replay`) showed one screen scoring 0.85 in replay and under 0.6 live: the tournament's confidence moves with how its 16-option groups fall, and the server warns that this checkpoint's calibration is invalid for 11+ options. Two fixes were tried:
- **Rejected:** asking Apple's model "does this command do what they asked?". It said yes to every command it was asked about in the next run, including "Start Speaking" for "there's no sound" and "Authorize This Computer" for "update my computer".
- **Kept:** a consistency check. The in-app tournament runs twice, with the options in opposite orders, and the person stays in the app only if both runs pick the same command with confidence ≥ 0.6.

With the consistency check (`ml/usecases/run.sh`):

| Start | Score |
|---|---|
| Finder | 12/14 |
| System Settings | 12/12 |
| TextEdit | 8/9 |
| Preview | 5/6 |
| Music | 3/3 |
| Risk check | 7/7 |
| **Total excluding Mail** | **47/51** |

The 3 recorded live steps of the demo journey (Taglish camera request from the Claude app → Apple menu → System Settings → Privacy & Security → Camera) replay 3/3.

## Experiment: Apple on-device model rewrites the goal first (rejected)
Apple's Foundation Model (on-device) restated each of the 127 validation goals as a plain action, at about 0.7 s per goal; it produced 122 rewrites. Scored with Laya v4e5 on the Mac:
- raw goal **102/127**
- goal + rewrite 92/127
- rewrite only 91/127

The rewrites hurt: the picker was trained on raw phrasings, and some rewrites change the intent. **Not used for picking.** Apple's model is used only to word the plan and hints for the step Laya already chose.

## Experiment: Apple on-device model judges Laya's top 3 (rejected), 2026-10-10
Laya v4e5's final-round top 3 for the 127 validation goals contain the right command **111/127** times (top-1: **102/127**). Apple's Foundation Model was shown the request plus those 3 commands and asked to pick one (37 s total, 124/127 answered):
- always use the judge: **102/127** (it fixed 6 and broke 6)
- use the judge only when Laya's top probability is < 0.9, 0.7 or 0.5: 103/127; < 0.3: 102/127

Net gain is within noise, so it's **not used**. Reproduce: `python3 experiments/val_top3.py` (needs laya-serve with `guide-v4e5`), then `swiftc -O experiments/judge_top3.swift -o judge && ./judge /tmp/sg/val_top3.json out.json`.

## "Wait, check first" risk check (yes/no)
Question: "Is someone getting this person to share their screen, install a remote-control app, or give away a code, password or PIN?" The test set is 30 goals in `ml/scam_eval.py` (14 risky, 16 look-alike normal), written before any run.

| Model | Threshold | Caught risky | False alarms |
|---|---|---|---|
| Laya base (local) | 0.4 | 6/14 | 0/16 |
| Laya v1 (local; never trained on this question) | 0.6 | 7/14 | 0/16 |
| Hosted Jev (cloud reference) | 0.4–0.5 | **14/14** | **0/16** |

Gabay runs the local model check (threshold 0.6) together with the keyword rules. The plan is to distill this question into the next model. Reproduce: `python3 scam_eval.py --model guide-v1` and `python3 scam_eval.py --url https://api.typesafe.ai --model jev-latest`.

## Teacher-label agreement (training apps)
Hosted Jev (`jev-latest`) on all 774 teacher goals across the 22 training apps: **733/774 (94.7%)** agree with the teacher label. Per app it ranges from 30/31 (Activity Monitor) to 35/35 (Disk Utility, VLC, Zed); median latency is 0.4–2.0 s.
- The 41 disagreements are mostly genuinely ambiguous goals, where both answers are often defensible.
- They're excluded from training as a consistency filter (`data/disagreements.json`), leaving 2,199 Laya rows.
- Log: `results/teacher_goals_jev.log`. Reproduce: `./run_teacher_bench.sh https://api.typesafe.ai jev-latest`.

## OpenAI Decisions API (cloud comparison only), 2026-10-10
OpenAI's Jev-like endpoint (`POST /v1/decisions`, public beta, `gpt-6-luna` only). Same task and wording as the hosted-Jev run: one `choice` question over the real command list. The API takes 2–255 choices, so Safari (256) uses the same 200-wide tournament. Only the sanitized fixtures were sent.
- **Validation first** (Activity Monitor, 30 goals): **29/30**, median 0.39 s per decision. Laya v6en scores 23/30 on the same app (16-wide tournament). The miss: "show how busy the computer is on the dock icon" → `View > Dock Icon > Show CPU History` (key: `Show CPU Usage`).
- **Held-out, run once:** Preview 9/10, Finder 8/8, System Settings 8/8, Safari 8/9 = **33/35**. Median per decision: 0.38–0.45 s, and 1.01 s for Safari (3 calls).
  - Preview "cut out just my face from the picture" → `Tools > Remove Background` (p 0.73).
  - Safari "make the words on this page bigger" → `View > Make Text Bigger` (p 0.98). This is the same arguable miss noted for Laya. The key is unchanged, so it counts as a miss.
- **Confidence:** `confidence` equalled the chosen option's probability on 62 of 65 decisions; on the other 3 it was 0.01–0.06 lower. When the chosen probability was ≥ 0.9, 50/51 picks were right.
- **Vision** (one call): a screenshot of https://www.wikipedia.org/ taken in a fresh headless Chrome profile, with the goal "I want to download the Wikipedia app on my phone". The answers were written before the run. It picked `link "Download Wikipedia for Android or iOS"` (p 1.0) and the grid cell `bottom left` (p 0.98); both are right. 2,062 input tokens, 1.09 s.
- **Cost:** 111,804 input tokens across everything above plus one smoke-test call = **$0.011** at the $0.10 / 1M input-token list price. Token counts come from `usage.input_tokens`; output isn't billed.
- **Not training data.** OpenAI's Services Agreement §3.3(e) forbids using Output to develop models that compete with OpenAI. The exceptions cover only classifiers that are not distributed, and fine-tuning OpenAI's own models. Laya ships to users, so these answers are a benchmark only.

Reproduce (needs `OPENAI_API_KEY` in `ml/.env`):
```bash
cd ml
python3 experiments/openai_decision_bench.py --fixture fixtures/val/activitymonitor.json
for f in preview finder systemsettings safari; do python3 experiments/openai_decision_bench.py --fixture fixtures/${f}_real.json; done
printf 'wikiportal https://www.wikipedia.org/\n' > /tmp/sites.txt && <venv with websockets>/bin/python web/crawl.py /tmp/sites.txt /tmp/sg/web
python3 experiments/openai_decision_bench.py --vision /tmp/sg/web/wikiportal.json --goal "I want to download the Wikipedia app on my phone" --expect 'link "Download Wikipedia for Android or iOS"' --expect-region "bottom left"
```

## Privacy findings
- **App menus contain personal data:**
  - recent files (with names)
  - browser history and page titles
  - account name and email (Music)
  - device names
  - window titles containing user, host and email (Terminal)
- **Earlier leak:** an early hosted-Jev run sent 10 recent Preview file names to TypeSafe before filtering existed. Since then, `make_fixtures.is_personal()` and `redact_names()` strip this before anything leaves the machine.
- **Pitch point:** even "just menu names" leak private data to a cloud model, which is a concrete argument for local inference.

## Training data (distillation)
- **Goals:** 774 teacher-written goals across 22 training apps (Claude Opus subagents, prompt: `ml/data/TEACHER_PROMPT.md`).
- **Validation:** every answer is verified to be a real command in that app's menus.
- **Rows:** 2,322 Laya rows (16-option groups with hard negatives), giving 1,914 train and 408 val. The val apps (Activity Monitor, Disk Utility, Numbers, Terminal) differ from both the train and the test apps.
