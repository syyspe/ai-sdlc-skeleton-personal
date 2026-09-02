---
name: sdlc
description: Use when the user asks where they are in the process, what to do next, how this repo's workflow works, how to start a piece of work, or what unlocks the next stage — and any time work is about to move from one stage to the next. Also user-invocable as /sdlc. Reports which of the six SDLC stages the current branch is in, derived from the artifacts on disk, and drives the next handoff.
---

# Where we are in the loop, and what's next

This repo runs the [AI-native
SDLC](https://claude.com/blog/the-ai-native-sdlc-playbook): six stages in a
loop, each ending by committing an artifact whose commit initiates the next
stage. There is no separate state to track — **the artifacts on the branch
are the state.**

## The loop

One short kebab-case slug (e.g. `csv-export`) names the branch and every
artifact on it.

| Stage | Artifact | Approved by | What unlocks the next stage |
|---|---|---|---|
| 1. Plan | `intent/<slug>.md` | Product owner | Intent committed with `status: approved` |
| 2. Design | `design/<slug>.spec.md` | Product owner, plus any policy owner a skill flagged | Spec committed with `status: approved` |
| 3. Build | `plans/<slug>.plan.md`, then the code | Engineer approves the plan in plan mode | Plan committed **before** any code |
| 4. Test | Passing verification + `verifier` verdict | The agent checks its own work first | Verification command passes and `verifier` reports PASS |
| 5. Deploy | PR with `REVIEW.md`'s four passes applied | A human — always | Human approves and merges |
| 6. Maintain | New `intent/<slug>.md` from a `bands.yaml` breach | Service owner triages | A breach past the top band writes the next intent → back to Stage 1 |

## Work out where you are

Read it off the branch, in this order — first match wins:

1. `git rev-parse --abbrev-ref HEAD`. On `main`/`master`, no work stream is
   checked out: the next action is Stage 1 on a new branch.
2. Otherwise the branch name is the slug. Check for `intent/<slug>.md`,
   `design/<slug>.spec.md`, `plans/<slug>.plan.md`, and read each one's
   `status:` frontmatter.
3. Missing artifact → you are in the stage that produces it. Present but
   `status: draft` → you are still in that stage, waiting on approval.
4. Plan present: `git status --porcelain` clean means implement or move to
   Stage 5; dirty means finish and verify (Stage 3 → 4).

The SessionStart hook (`.claude/hooks/session-start-check.sh`) runs the same
rules once per session. Re-derive them here rather than trusting a stale
reading from the top of the conversation.

## What to do at each stage

**Stage 0 — nothing started.** Agree a slug with the user, then
`git checkout -b <slug>`. Running two streams at once? Use the `worktree`
skill instead of switching branches in place.

**Stage 1 — Plan.** Copy `intent/TEMPLATE.md` to `intent/<slug>.md` and fill
it by interviewing the user — Problem, Proposed outcome, Affected systems,
Constraints, Open questions — one question at a time. Write what they
actually said; don't invent constraints to fill the section. Commit it.
Then stop: a product owner reviews and flips `status: approved`. Anyone can
start an intent; no engineering knowledge required.

**Stage 2 — Design.** Only once the intent reads `status: approved`. Draft
`design/<slug>.spec.md` from it using `design/TEMPLATE.spec.md`. Requirements
get enumerated, not prosed — Stage 3 plans are checked against them and Stage
5 review checks compliance against them. Every policy skill in
`.claude/skills/` that matches applies here; record what each raised, and how
it was resolved, under **Policy flags**. Unresolved flags go to that policy's
owner before the product owner approves.

**Stage 3 — Build.** Only once the spec reads `status: approved`. Start in
plan mode against the spec and iterate until an engineer who has never seen
the conversation could implement from the plan alone. Commit it as
`plans/<slug>.plan.md` *before* writing code — that commit is the audit
trail Stage 5 compares the diff against. Then implement. `simple-code`
applies from the first line. If the implementation departs from the plan,
update `plans/<slug>.plan.md` in the same commit rather than letting them
drift.

**Stage 4 — Test.** Run the verification command from `CLAUDE.md`'s Commands
section and report its real output, not a paraphrase. For a bug fix, commit
the failing test *before* the fix and don't edit it while fixing. Then hand
the change to the `verifier` subagent — fresh context, checks the diff
against the plan. Fix what it finds before a human sees the change.

**Stage 5 — Deploy.** Run `/code-review` (it applies `REVIEW.md`'s four
passes: Bugs, Security, Compliance, Simplicity), then push the branch and
open a PR — `git push -u origin <slug> && gh pr create`. The default branch
is PR-only and `default-branch-guard.sh` blocks a direct push to it, so
there is no shortcut here even for a one-line change. Claude's findings are
advisory; a human approves the merge. Hooks gate anything hard to reverse —
if one blocks you, that's a signal to ask a human, not to work around it.
After merge, a bug fix's regression test belongs in `evals/` too.

**Stage 6 — Maintain.** A monitoring script watches SLOs against `bands.yaml`.
A breach past the top band writes a new `intent/*.md` with the anomaly
evidence, and the loop starts again at Stage 1. Each incident class also
becomes a permanent eval.

## Rules that don't bend

- Don't skip a stage, and don't start one whose upstream artifact is still
  `status: draft`. Waiting on a human approval is the process working, not a
  blocker to route around.
- Nothing gets implemented without a committed plan.
- Report where things stand compactly — a status line and the next action —
  then offer to do that next step. Do it once the user agrees; don't run
  several stages together unasked.
