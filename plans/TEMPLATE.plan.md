---
status: draft # draft | approved | implemented
spec: design/<matching-file>.spec.md
branch: <branch-name>
date: <YYYY-MM-DD>
---

# <Short title> — Plan

## Affected files

- `<path>` — `<what changes and why>`

## Work order

1. ...
2. ...

## Tests

- New: `<test to add>`
- Updated: `<test to update>`
- Verification command: `<the command from CLAUDE.md that must pass>`

## Risks / rollback

Anything hard to reverse, and how to roll back if it goes wrong.

---

**Next stage:** commit this plan *before* writing code. Then implement the
work order, run the verification command above, and hand the change to the
`verifier` subagent (Stage 4) before opening a PR (Stage 5).
