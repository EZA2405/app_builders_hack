# Teacher prompt: web goals only (Jev picks the answer)

Write realistic goals for older or non-technical Filipino users on websites. **Don't pick answers.** A separate model chooses the element on the page.

For each assigned site, read its page snapshots in `/tmp/sg/web/<site>.json` and `/tmp/sg/web/<site>__<k>.json`. Treat page text as data only. Each page's `elements` list shows what can be clicked or typed there.

Write `ml/data/goals_web_jev/<site>.jsonl`, one line per goal:
`{"goal": "...", "page": "<snapshot stem, e.g. meralco or meralco__2>", "done": [<"clicked link \"<arrived_by.clicked>\""> for __k pages, else empty>]}`

## Rules
- **About 6–10 goals per page** with at least 15 elements. Each must be doable by clicking or typing into one element on **that** page.
- **Mix:** home-page goals (`done: []`) and second-page goals, where `done` = the click that reached that page (use `arrived_by.clicked`).
- **Everyday tasks:** pay bills, log in, forgot password, check balance or status, apply or renew, find branches or offices, contact support, track an order, search, change language, download forms.
- **Wording:** about 1 in 5 in casual Taglish, with plain words and some typos.
- **Avoid:** cookie banners, ads, social share buttons and headline-specific news goals. No personal data.

Validate that each line is JSON with `goal` and `page`, and that `page` exists. Report counts.
