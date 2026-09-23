# AI-Native SDLC Skeleton (personal scale)

A starter repo for running your own projects with Claude embedded at every
stage. Adapted from the [AI-Native SDLC
Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook), with the
organizational scaffolding taken out: no product owners, no policy owners, no
sign-off chain, no SLO control bands, no on-call routing. One person, working
on their own things, with an agent that has enough structure to stay honest.

The core idea survives the shrink: **every stage produces a version-controlled
artifact the next stage reads.** You stay accountable for judgment calls
(what to build, whether the plan is right, whether it merges); Claude does the
work in between.

```
brief.md  →  plan.md  →  code + tests  →  PR
 (Brief)     (Plan)      (Build)          (Ship)
```

Every session opens by telling you which stage the current branch is in and
what's next; **`/sdlc`** re-answers that any time you ask. The stage table and
rules are in `.claude/skills/sdlc/SKILL.md`.

## Prerequisites

- **git**
- **[Claude Code](https://claude.com/claude-code)** (the `claude` CLI)
- **python3** — the hooks in `.claude/hooks/` parse tool-call data with it,
  unconditionally, regardless of your project's stack. Without it, every
  Edit/Write/Bash call gets blocked by a raw shell error instead of the
  hook's actual guardrail message.
- **[`gh`](https://cli.github.com)**, authenticated — the default branch is
  PR-only, so opening PRs is part of the normal flow, starting with
  bootstrap's own setup PR. Without it nothing breaks; you just open each PR
  in a browser from a compare URL instead.

## The default branch is PR-only

Nothing lands on the default branch except by merged pull request. On a solo
project that isn't about permission — you're the reviewer — it's about
forcing the diff to be *looked at*, once, in one place, instead of
accumulating as a string of direct commits nobody ever reads back.
`.claude/hooks/default-branch-guard.sh` blocks a direct push from any Claude
session here (escape hatch: `ALLOW_DEFAULT_PUSH=1`, for when you've decided
to take that on).

If this rule stops paying for itself on some project, delete the hook from
`.claude/settings.json`. It's a default, not a law.

## Getting started with a new project

1. On GitHub, click **Use this template** on this repo → create your new
   repo (clean history, no link back to this skeleton).
2. Clone it locally.
3. Run `claude` in it, then run **`/bootstrap`**. Setup starts right away,
   one question at a time (project name, purpose, tech stack, commands).
   For a known stack (Next.js, Django, React+Vite, plain Node/TS) it
   offers to scaffold the project too, then fills in every `<placeholder>`
   across `CLAUDE.md`, `README.md`, `REVIEW.md`, and `.claude/hooks/`. If
   you forget, any first message will still trigger it — an unconfigured
   clone is detected automatically — but `/bootstrap` is the reliable way
   to kick it off. Re-run any time (e.g. if the stack changes later). It
   ends by putting the setup on a `bootstrap-setup` branch and opening a
   PR — the default branch is PR-only here, and setup is no exception.
4. **Merge that setup PR**, then tell Claude. It pulls the default branch
   and walks you into Stage 1. The merge has to happen first: the
   `.claude/.bootstrapped` marker must be tracked and reachable from the
   default branch, or parallel worktrees look unconfigured and re-bootstrap
   themselves, and any branch you fork before the merge carries the whole
   scaffold in its diff.
5. **You're in the loop.** Bootstrap shows the four-stage map, asks what you
   want to build first, and writes your first `brief/<slug>.md` with you on
   a new branch.
6. *(Optional)* set the `ANTHROPIC_API_KEY` secret on the new GitHub repo
   (Settings → Secrets → Actions) so `.github/workflows/claude-review.yml`
   can review your PRs automatically. Without it the workflow skips cleanly
   and explains itself in the run summary — your PRs stay green, they just
   don't get automated review until you opt in. `/review` in a local session
   covers the same `REVIEW.md` passes with no key and no CI minutes — see
   that file. Note that the key is billed to whoever owns it: turning this on
   means you pay for a review of every PR on that repo. It's opt-in per repo
   for that reason, rather than something bootstrap switches on for you.
7. *(Optional)* **Trim or extend `.claude/skills/`** with anything specific
   to this project that `CLAUDE.md` is the wrong place for.

Bootstrap deliberately leaves the `brief/` and `plans/` templates alone —
those fill in from real use, not initial setup.

### Maintaining this skeleton itself

This repo needs to be marked as a **GitHub template repository** for step 1
above to work: `gh repo edit <owner>/<repo> --template`, or Settings →
General → check "Template repository". One-time setup, done once this repo
is pushed.

## Working on something

Run `/sdlc` and Claude tells you where the current branch stands and what to
do next. The instructions for each stage are in `.claude/skills/sdlc/stages/`,
and the reasoning behind the process is in
`.claude/skills/sdlc/session-economy.md`. Working on more than one thing at a
time? Use the `worktree` skill (`.claude/skills/worktree/SKILL.md`) instead of
switching branches in place.

## Repository layout

| Path | Stage | Purpose |
|---|---|---|
| `brief/` | 1. Brief | Problem framing + requirements, one file per piece of work |
| `plans/` | 2. Plan | Implementation plans, one per branch/PR, committed as the audit trail |
| `CLAUDE.md` | all | Project knowledge Claude reads every session |
| `.claude/skills/` | 2–3 | Triggered policy skills |
| `.claude/skills/sdlc/` | all | `/sdlc` — which stage the branch is in, and what's next |
| `.claude/hooks/` | 3, 4 | Deterministic guardrails and approval gates |
| `.claude/agents/` | 4 | Subagents for repeated tasks (verification) |
| `.claude/settings.json` | all | Wires hooks into tool events |
| `REVIEW.md` | 4. Ship | PR review policy — read by the CI workflow and by local `/review`, not by the built-in `/code-review` |
| `.github/workflows/claude-review.yml` | 4. Ship | Optional CI that runs `REVIEW.md`'s passes on every PR |

## What this skeleton deliberately leaves out

- No language/stack is assumed — commands in `CLAUDE.md` and hook scripts are
  placeholders you fill in.
- **No approval workflow.** No `status: draft|approved`, no sign-off lines,
  no roles. You approve things by committing them.
- **No monitoring loop.** The upstream playbook closes Stage 6 back to Stage
  1 via SLO control bands and on-call routing. That needs a metrics stack and
  a rotation; a personal project has neither. When something breaks, you
  notice, and you write a brief.
- **No agent-config eval suite.** The playbook regression-tests `CLAUDE.md`
  and `.claude/**` with a 20–50 task eval suite in CI. That's a real
  practice, and it's real work to maintain — out of proportion here. The
  substitute is the "Things Claude gets wrong here" section of `CLAUDE.md`:
  when a mistake recurs, write it down there.

## License

[MIT](LICENSE). Copy it, fork it, sell whatever you build with it.

`LICENSE` gets copied into every repo made from this template, which is
almost certainly not what you want downstream — **replace it with your own
before your project goes anywhere.** The scaffolding here isn't the part
you'll want to license to anyone.
