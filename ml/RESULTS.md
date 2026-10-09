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

## Experiment: Apple on-device model rewrites the goal first (rejected)
Apple's Foundation Model (on-device) restated each of the 127 validation goals as a plain action, at about 0.7 s per goal; it produced 122 rewrites. Scored with Laya v4e5 on the Mac:
- raw goal **102/127**
- goal + rewrite 92/127
- rewrite only 91/127

The rewrites hurt: the picker was trained on raw phrasings, and some rewrites change the intent. **Not used for picking.** Apple's model is used only to word the plan and hints for the step Laya already chose.

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
