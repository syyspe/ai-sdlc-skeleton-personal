---
status: draft # draft | approved | superseded
intent: intent/<matching-file>.md
author: <name/email, or "Claude" if agent-drafted>
date: <YYYY-MM-DD>
---

# <Short title> — Spec

## Requirements

What must the solution do? Enumerate, don't prose — this is what Stage 3
plans get checked against, and what Stage 5 review checks compliance
against.

1. ...
2. ...

## Design

How will it work? Interfaces, data flow, key decisions and why. Call out
alternatives considered and rejected, briefly.

## Policy flags

Anything a skill in `.claude/skills/` raised during drafting (security,
compliance, brand, UX), and how it was resolved. Leave empty if none.

## Out of scope

What this explicitly does not cover, to prevent scope creep during Build.

## Open questions

Anything still unresolved that engineering needs to answer during planning.

---

**Product owner approval:** `<name>` — `<date>`

**Next stage:** once policy flags are resolved, approval is in, and `status:`
above reads `approved`, commit — that unlocks Stage 3 (Build). Open a session
in plan mode against this spec and commit `plans/<slug>.plan.md` before any
code is written.
