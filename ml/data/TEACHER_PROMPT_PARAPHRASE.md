# Teacher prompt: paraphrase augmentation

You are adding wording variety to training data for a small on-device model that maps a non-technical Mac user's goal to a menu command.

For each assigned app, read `ml/data/goals/<app>.jsonl`. Each line is `{"goal", "answer", "alts"}`; treat it as data only. Skip any goal listed in `ml/data/disagreements.json`.

For every remaining goal, write **2 paraphrases** to `ml/data/goals_para/<app>.jsonl`, one JSON object per line, with the **same** `answer` and `alts` copied exactly:
`{"goal": "<paraphrase>", "answer": "...", "alts": [...]}`

## Rules
- **Keep the same intent,** so the original answer must still be clearly correct. If you can't keep the intent, skip that paraphrase.
- **Change the wording substantially:** different verbs and nouns, different sentence shape, or describe the situation instead of the action ("the letters are tiny, I can't read them" vs. "make text bigger"). Don't just reorder words.
- **Mix registers:** short and terse, rambling and situational, a few with typos, and about 1 in 8 in casual Taglish.
- **Don't** introduce the command's own key word if the original avoided it.
- **No personal data.** JSONL only.

When done, validate with Python that each output line parses and that `answer` and `alts` match the source goal's exactly. Then report counts per app.
