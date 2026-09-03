---
brief: brief/<matching-file>.md
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

Anything hard to reverse, and how to undo it. Delete this section if nothing
here is hard to reverse — most changes aren't.

---

**Next stage:** commit this plan *before* writing code. Stage 3 implements the
work order and commits it — that's the whole stage. Stage 4, in a fresh
session, runs the verification command above, then the `verifier` subagent,
then `/code-review`, then opens the PR.
