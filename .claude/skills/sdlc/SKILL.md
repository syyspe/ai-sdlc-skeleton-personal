---
name: sdlc
description: Use when the user asks where they are in the process, what to do next, how this repo's workflow works, how to start a piece of work, or what unlocks the next stage — and any time work is about to move from one stage to the next. Also user-invocable as /sdlc. Reports which of the four stages the current branch is in, derived from the artifacts committed on the branch, and drives the next handoff.
---

# Where we are in the loop, and what's next

This repo runs a personal-scale adaptation of the [AI-native
SDLC](https://claude.com/blog/the-ai-native-sdlc-playbook): four stages, each
ending by committing an artifact whose commit initiates the next stage. There
is no separate state to track and nothing to approve — **the artifacts on the
branch are the state.**

One slug names the branch and every artifact on it: a three-digit sequence
number plus a short kebab-case name (e.g. `007-csv-export`), so `brief/` and
`plans/` list in the order the briefs were written. The number is one more
than the highest already taken — by a branch name or by a brief on any
branch, local or remote, so parallel streams and an open backlog PR don't
collide:

```bash
git fetch --quiet origin
git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin \
  | while read -r ref; do echo "$ref"; git ls-tree --name-only "$ref" brief/; done \
  | sed -nE 's#^(.*/)?([0-9]{3})-.*#\2#p' | sort -n | tail -1
```

No output → `001`.

## Which streams exist

The same rule holds across streams: their state is read off git, never
stored in a status field.

```bash
git fetch --quiet origin
bash .claude/skills/sdlc/streams.sh
```

One line per slug: **done** (its plan is on the default branch — only a
merged PR puts it there), **in progress** (a branch named for it exists, with
the stage read off that branch), or **not started** (its brief is on the
default branch and nothing else is). The script's header says why done is
checked first.

**Backlog.** To write briefs now and start them later, write them on a
branch named `backlog-<short-name>` (no number: it orders nothing itself),
each brief taking its own number, and open a PR. That session is Stage 1
only — no plans, no code — and ships by Stage 4's light path. Once merged,
each brief shows as not started.

**Dropping a brief.** Delete `brief/<slug>.md` in a PR (a backlog PR is
fine); history keeps it. If its branch exists, delete that too, or it keeps
showing as in progress. Don't add a status field for it.

| Stage | Artifact | Instructions | Ends when | Next session |
|---|---|---|---|---|
| 1. Brief | `brief/<slug>.md` | `stages/1-brief.md` | Brief committed | Stage 2 — in plan mode |
| 2. Plan | `plans/<slug>.plan.md` | `stages/2-plan.md` | Plan committed **before** any code | Stage 3 — auto mode |
| 3. Build | The code and its tests | `stages/3-build.md` | Code committed | Stage 4 |
| 4. Ship | Verification, review, and a PR | `stages/4-ship.md` | The user reads the PR and merges | — |

Paths are relative to this skill's directory. **Read only the stage file you
land in.**

Why the process is shaped this way: `session-economy.md` in this directory.

## Work out where you are

Read it off the branch, in this order — first match wins:

1. `git rev-parse --abbrev-ref HEAD`. On `main`/`master`, no work stream is
   checked out: see Stage 0 below. On `backlog-*`, this is a backlog
   session — see "Which streams exist".
2. Otherwise the branch name is the slug. An artifact counts only once it is
   committed: `git cat-file -e HEAD:<path>` succeeds for `brief/<slug>.md`
   and `plans/<slug>.plan.md`. An artifact not in `HEAD` → you are in the
   stage that produces it; if the file is already on disk, that stage's next
   action is to commit it.
3. Both committed, `git status --porcelain` dirty → Stage 3, in progress.
4. Both committed, tree clean → has code landed since the plan?

   ```bash
   plan_commit=$(git log --diff-filter=A --format=%H -1 -- "plans/$slug.plan.md")
   git log "$plan_commit"..HEAD -- . ':(exclude)brief' ':(exclude)plans'
   ```

   Output → Stage 4. Empty → Stage 3, not started. Date it from the commit
   that *added* the plan, not the last one to touch it.

The SessionStart hook (`.claude/hooks/session-start-check.sh`) runs the same
rules once per session and names the stage file. Re-derive them here rather
than trusting a stale reading from the top of the conversation — a commit
landing mid-session moves the branch to the next stage.

**Stage 0 — nothing checked out.** Run "Which streams exist" above. If any
brief is not started, offer those first, lowest number first, alongside the
option of a new one — the user picks:

- **A not-started brief** — `git checkout -b <slug> origin/HEAD`. Its brief
  is already committed, so the branch opens at Stage 2.
- **A new one** — take the next number, agree the name part of the slug with
  the user, then `git checkout -b <slug>`. Stage 1.

Never start a slug that is already in progress: that stream has a branch,
and probably a session. Running two streams at once? Use the `worktree`
skill instead of switching branches in place.

## Handing off between stages

At each "Ends when" in the table: say the stage is done, name the next action
in one line, suggest a fresh session (in the table's mode), and
stop there. Don't take the next stage's first action in the same message, and
don't offer to. Say it once — if the user would rather keep going, keep going.

## Rules that don't bend

- Nothing gets implemented without a committed plan. This is the one hard
  rule; the rest is a default path.
- One session, one stage. A stage ends where the table above says it ends,
  and the next stage's first action belongs to the next session. Suggest the
  handoff instead of starting the work and mentioning the handoff afterwards.
- Don't run several *stages* together unasked. At a boundary, report where
  things stand compactly — a status line and the next action — and hand off;
  move on in the same session only if the user asks to. This governs stage
  transitions, not the steps inside a stage: Stage 4's steps run back to back
  without checking in between.
- For a genuinely trivial change (typo, version bump, one-line fix with an
  obvious test), say so and go straight to a branch and a PR — its branch
  name takes no number, since it leaves no artifacts to order. Skipping the
  brief is a judgment call to make out loud. Skipping the plan on anything
  larger than that is not.
