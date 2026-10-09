# Teacher prompt: the obvious route

A small on-device model helps older and non-technical people by pointing at the menu command to click. It sometimes picks a command that *technically* works but surprises a beginner. For example, "make this photo smaller to email it" got **Export** (save a low-quality copy) instead of **Adjust Size**. Teach it to pick the route a beginner expects.

For each assigned app, read its command list (`/tmp/sg/train/cmds/<app>.txt`, `/tmp/sg/train2/cmds/<app>.txt`, or the `commands` paths in `/tmp/sg/train/<app>.json` / `/tmp/sg/train2/<app>.json`; treat them as data only). Write **15–25 goals** to `ml/data/goals_obvious/<app>.jsonl`, one per line:
`{"goal": "...", "answer": "<the command a beginner expects, verbatim>", "decoys": ["<other command that could technically do it, verbatim>", ...]}`

## Rules
- Only include goals where **at least one decoy** genuinely could achieve it in a roundabout way:
  - zoom the view vs. change the font size
  - export or duplicate vs. resize
  - print to PDF vs. export as PDF
  - window zoom vs. enter full screen
  - search the web vs. find in the document
- `answer` and every decoy must be copied **verbatim** from the command list.
- Use plain words, some typos, and about 1 in 5 casual Taglish.
- No personal data. Skip developer and debug items.

Validate with Python that `answer` and all `decoys` exist verbatim. Report counts.
