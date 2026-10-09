# AGENTS.md

Instructions for AI coding agents (Claude Code, Codex, Devin, etc.) working in this repo.

## Context
- **Event:** AppBuildersPH Hackathon 2026, theme **Local AI**. The project is ScreenGuide (working name), a macOS guide that highlights the next control to click in any app, chosen by a **local** model.
- **Hard deadline: 10:00 AM, Oct 10, 2026 (PH time).** Code freezes then and the repo must be public. Prefer small, working, demo-able increments over broad rewrites.
- **Rules and judging:** read `docs/hackathon/briefing.pdf` (`pdftotext -layout`) and `docs/hackathon/kickoff-transcript.txt`.
  - Judging: problem 25%, how real the local AI is 25%, works live 20%, innovation 15%, demo/UX 15%.
- **Product principles:** the guide **points; the user clicks**. Never add autonomous clicking or typing. Plain, calm language for older users.

## Layout
- `app/`: Swift package → `ScreenGuide.app`.
  - Build: `app/scripts/build_app.sh` (signs with the local Apple Development identity so the Accessibility grant survives rebuilds).
  - Dev dump mode: `open -W -n app/build/ScreenGuide.app --args --dump <App> <out.json> [--menus-only]`.
- `ml/`: Python (stdlib only for scripts).
  - `bench_localjev.py`: any Jev-compatible `/v1/systemone` server.
  - `make_fixtures.py`: sanitizer + held-out fixtures.
  - `build_trainset.py`: Laya rows.
  - `dump_apps.sh`: menu dumps of training apps.
- `extension/SPEC.md`: Chrome extension contract (WebSocket `127.0.0.1:47823/ext`).
- `design/`: UI design prompt and assets.

## Local services (dev)
| Service | Port | Start |
|---|---|---|
| local-jev (Qwen3.5-4B) | 8765 | `local-jev serve --model llm-qwen3.5-4b` (separate checkout, `../local-jev`) |
| Laya | 8766 | `LAYA_HOST=127.0.0.1 LAYA_PORT=8766 LAYA_DEVICE=mps laya-serve` |
| Extension bridge | 47823 | served by the Mac app (planned) |

## Non-negotiable rules
1. **Never send unsanitized screen data to any cloud service.** Menus contain recent files, browser history, account names, emails and device names.
   - Anything leaving the machine goes through `ml/make_fixtures.py` `is_personal()` + `redact_names()` first.
   - The product's decision path must run locally.
2. **Held-out apps never enter training:** Preview, Finder, System Settings, Safari. `build_trainset.py` enforces this. Don't weaken it.
3. **Only report measured numbers.** Fake benchmarks are disqualifying.
   - Add results to `ml/RESULTS.md` with the date and the reproduce command.
   - Never edit answer keys after seeing model output unless the key was factually wrong (e.g. the real command name differs), and note it.
4. **Secrets** live in `ml/.env` (gitignored; e.g. `JEV_API_KEY`). Never print, log or commit them.
5. **Disclose** every model, API, dataset source and AI tool in `README.md`.

## Conventions
- **Swift:** tools 6.2, macOS 26 target, Swift 5 language mode. AppKit + SwiftUI. Keep the overlay a transparent, non-activating, click-through panel.
- **Python:** 3.12+. Scripts stay stdlib-only unless they're training code.
- **Match the surrounding code style.** Comment the *why*, not the *what*.
- **Commits:** small and descriptive. Don't commit `app/.build`, `app/build`, model weights or `.env`.

## Shared workflow

- Read README.md for project context.
- Before starting tracked work, assign yourself the GitHub issue.
  If someone already owns it, coordinate before changing its scope.
- Use a branch per issue and a separate checkout or worktree when
  working concurrently. Preserve other contributors’ uncommitted work.
- Submit changes through a PR linked to the issue. Include what changed
  and how it was checked; request another contributor’s review before merging.
- Keep acceptance criteria and progress in the issue, and resolved domain
  terms and architecture decisions in the glossary and ADRs.

## Agent skills

### Issue tracker

Shared GitHub Issues in EZA2405/app_builders_hack.
Read `docs/agents/issue-tracker.md` before ticket operations.

### Triage labels

Use the five default triage labels.
Read `docs/agents/triage-labels.md` before triaging issues.

### Domain docs

Single-context: root GLOSSARY.md and docs/adr/.
Read `docs/agents/domain.md` before exploring the project.
