# Issue tracker: GitHub

Issues and specs live in EZA2405/app_builders_hack on GitHub.
Use the gh CLI from this clone.

- Create: gh issue create --title "..." --body-file <file>
- Read: gh issue view <number> --comments
- List: gh issue list --state open --json number,title,labels,assignees
- Claim: gh issue edit <number> --add-assignee @me
- Comment: gh issue comment <number> --body-file <file>
- Label: gh issue edit <number> --add-label "<label>"
  or --remove-label "<label>"
- Close: gh issue close <number> --comment "..."

When a skill says "publish to the issue tracker", create a GitHub issue.
When it says "fetch the relevant ticket", read the issue and comments.

## Pull requests as a triage surface

**PRs as a request surface: no.**
