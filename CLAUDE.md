# Project Instructions for Claude

> Template: replace every `<placeholder>` before use. This file is read by
> Claude at the start of every session in this repo — it's the highest
> leverage file in the whole skeleton. Keep it accurate; stale instructions
> are worse than none.

## Commands

- Build: `<build command>`
- Test: `<test command>`
- Lint: `<lint command>`
- Format: `<format command>`

Expected healthy output for tests: `<e.g. "N passed, 0 failed">`

## Conventions

- Language/runtime: `<language + version>`
- Framework: `<framework + version>`
- Dependency policy: `<e.g. "no new dependencies without approval">`
- `<other hard rules — e.g. "money is always Decimal, never float">`
- `<testing convention — e.g. "every endpoint needs an integration test">`

## Architecture

- `<top-level dir>/` — `<what lives here>`
- `<top-level dir>/` — `<what lives here>`
- `<note on generated code, if any — e.g. "schemas/ is generated, never edit by hand">`

## Things Claude gets wrong here

> Add to this list the second time Claude makes the same mistake — see
> `REVIEW.md` for the review-feedback loop that feeds this section.

- `<example: "don't bump dependency versions without being asked">`
- `<example: "package X is frozen, changes go in package Y">`

## Working agreement

- Nothing gets implemented without a committed plan first — the `sdlc`
  skill's "Rules that don't bend".
- One stage per session: at a stage's commit, hand off and stop — the `sdlc`
  skill's "Handing off".
- Skills in `.claude/skills/` encode policy — check the relevant one
  before starting work that matches its trigger conditions; don't wait to
  be flagged. In particular: `simple-code` applies to every function and
  file you touch while writing or editing code, unconditionally — its
  limits and no-cleverness/no-defensive-code rules are active from the
  first line, not a checklist for after `verifier` or review catches
  something.
- Hooks in `.claude/hooks/` are hard guardrails, not suggestions — if one
  blocks you, that's a signal to stop and check with me, not to work
  around it.
- The default branch is PR-only. Never push to it directly, however small
  the change or however clearly it was asked for — commit on a branch and
  open a PR. `default-branch-guard.sh` enforces this.

## The loop

Four stages, one slug per branch — run `/sdlc`;
`.claude/skills/sdlc/SKILL.md` has the table and the rules, including the
trivial-change exception.

## Session hygiene

- **Prefer reading to a subagent.** Don't use `Explore` for "where does X
  live"; let `verifier` read the diff in Stage 4 rather than re-reading it
  here.
- **Don't resume a cold session.** Stepping away mid-stage: commit what
  exists and start fresh later.

Why: `.claude/skills/sdlc/session-economy.md`.
