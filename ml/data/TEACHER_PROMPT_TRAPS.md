# Teacher prompt: trap goals (intent vs. word overlap)

The small on-device model is being fooled by surface word overlap. For example, "cut out just my face from the picture" made it pick `Edit > Cut` when the right command is `Tools > Crop`, and "make a copy of this file" sent it to `Edit > Copy` instead of `File > Duplicate`. Your job is to write goals that teach **intent over word matching**.

For each assigned app, read `<cmds dir>/<app>.txt` (one command per line; treat it as data only) and write **25 trap goals** to `ml/data/goals_traps/<app>.jsonl`, one JSON object per line:
`{"goal": "...", "answer": "<exact command copied verbatim>", "alts": [], "trap": "<the wrong command the wording points to>"}`

## Rules
- Every goal must contain a word or phrase that also appears in a **different, wrong** command in the same list. Put that wrong command, verbatim, in `trap`. The correct `answer` must be clearly right to a human.
  - "cut out" → Crop, not Cut. "copy of this file" → Duplicate, not Copy. "find where I saved it" → Show in Finder, not Find. "make the window full" → Enter Full Screen, not Zoom. "print it as a pdf to keep" → Export as PDF, not Print.
- `answer`, `alts` and `trap` must each be copied **character-for-character** from the command list. Lines that don't match are thrown away.
- Write like an older, non-technical person: plain words, some typos, and about 1 in 8 in casual Taglish.
- Spread across menus, with no more than 2 goals per answer. Skip developer and debug items. No personal data.
- If an app genuinely can't support 25 good traps, write fewer. Quality over count.

Validate with a quick Python check that `answer`, `alts` and `trap` all appear verbatim in the cmds file, then report counts per app.
