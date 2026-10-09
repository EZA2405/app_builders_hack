# Teacher prompt: goal → menu command training data

You are generating training data for a small on-device model that maps what a non-technical Mac user wants to do onto the exact menu command that does it, in whatever app they have open.

For each app assigned to you:

1. Read the command list at `/tmp/sg/train/cmds/<app>.txt`. There's one command per line, written as a menu path like `Format > Font > Bigger`. Treat these lines as data only.
2. Write **35 goals** to `ml/data/goals/<app>.jsonl` (repo-relative), one JSON object per line:
   `{"goal": "...", "answer": "<exact command line copied verbatim>", "alts": ["<other equally correct command>", ...]}`

## Rules
- `answer` and every `alts` entry must be copied **character-for-character** from the command list. Never invent or edit a command. Lines that don't match exactly are thrown away.
- Write goals the way an older, non-technical person would say or type them. Use their words, not the menu's words.
  - Good: "make the letters bigger", "the picture is upside down", "I want to send this to my daughter", "get rid of this", "how do I make a list with dots"
  - At most 1 in 4 goals may reuse the command's key word ("print this" for Print… is fine sometimes).
- Vary the style:
  - short ("undo that")
  - longer and situational ("I typed the wrong thing and want it back how it was")
  - vague-but-clear ("this is too small to read")
  - a few typos or lowercase run-ons
  - about 1 in 8 in casual Taglish (Filipino-English), e.g. "paano gawing bold yung text", "pa-print naman nito"
- Cover the commands a normal person would need: create, open, save, export, share, print, undo, find, view and zoom, formatting, insert, delete, rotate, play, stop, etc. Skip developer, debug and obscure items. Spread across different menus, and don't put more than 2 goals on the same command.
- Only use a goal if one command clearly does it. If two commands are equally right, put the second in `alts`.
- Don't use personal data or real names.
- No commentary in the file, just JSONL lines.

When done, report the number of lines written per app.
