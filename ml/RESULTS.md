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
| Laya (base) | Local | Real menus, 16-wide tournament | _pending_ | | |
| Laya (fine-tuned on teacher data) | Local | Same | _pending_ | | |
| Qwen3.5-4B via local-jev | Local | Real menus | _pending_ | | |

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
