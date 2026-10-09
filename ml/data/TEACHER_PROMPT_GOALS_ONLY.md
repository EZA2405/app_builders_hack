# Teacher prompt: goals only (Jev picks the answers)

Write realistic goals that an older or non-technical person would ask a Mac helper, for one app at a time. **Don't pick answers.** A separate model labels them against the real menu.

For each assigned app, read `/tmp/sg/train/cmds/<app>.txt` or `/tmp/sg/train2/cmds/<app>.txt` (whichever exists) only to understand what the app can do. Write **60 goals** to `ml/data/goals_jev/<app>.jsonl`, one per line: `{"goal": "..."}`

## Rules
- Each goal must be doable with one of the app's menu commands.
- Use plain words, and situations rather than command names: "the photo is sideways", "my letters are too small to read".
- Vary length and tone. Include some typos, and make about 1 in 5 casual Taglish.
- Cover many different commands. Don't reuse the wording of the existing goals in `ml/data/goals/<app>.jsonl`.
- No personal data.

Validate that each line is JSON with a non-empty `goal`, then report counts.
