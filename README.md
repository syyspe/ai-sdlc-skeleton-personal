# AI-Native SDLC Skeleton

A starter repo for running the full software development lifecycle with Claude
embedded at every stage, following the [AI-Native SDLC
Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook). Clone this
into a new project to get the artifact chain, guardrails, and eval loop
scaffolded from day one.

The core idea: every stage produces a version-controlled artifact the next
stage reads. Humans stay accountable for judgment calls (approving specs,
plans, and production releases); Claude does the work in between.

```
intent.md  →  spec.md  →  plan.md  →  PR + tests  →  deploy  →  monitoring
 (Plan)       (Design)     (Build)     (Test/Review)  (Deploy)   (Maintain)
```

Each stage ends by committing its artifact, and that commit is what starts
the next one:

| Stage | Artifact | Done when | Which unlocks |
|---|---|---|---|
| 1. Plan | `intent/<slug>.md` | product owner sets `status: approved` | Design |
| 2. Design | `design/<slug>.spec.md` | policy flags resolved, product owner sets `status: approved` | Build |
| 3. Build | `plans/<slug>.plan.md`, then code | plan committed **before** code, work order done | Test |
| 4. Test | verification output, `verifier` verdict | the command in `CLAUDE.md` passes and `verifier` says PASS | Deploy |
| 5. Deploy | PR reviewed per `REVIEW.md` | a human approves and merges | Maintain |
| 6. Maintain | `bands.yaml` breach → new `intent/*.md` | the breach is triaged | Plan, again |

You never have to hold that in your head. Every session starts by telling
you which stage the current branch is in and what the next action is, and
**`/sdlc`** re-answers that any time you ask.

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
- **jq** — only needed to run `evals/run.sh` locally (Stage 4). CI installs
  it itself, so you can skip this until you run evals by hand.

## The default branch is PR-only

Nothing lands on the default branch except by merged pull request — that's
what makes `REVIEW.md`'s passes and human approval unskippable rather than
optional. `.claude/hooks/default-branch-guard.sh` blocks a direct push from
any Claude session here (escape hatch: `ALLOW_DEFAULT_PUSH=1`, for a human
who has decided to take that on). Pair it with branch protection on the
remote for the half a local hook can't cover — see step 8 below.

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
   clone is detected automatically and setup takes over before anything
   else — but `/bootstrap` is the reliable way to kick it off. Re-run any
   time (e.g. if the stack changes later). It ends by putting the setup on a
   `bootstrap-setup` branch and opening a PR — the default branch is PR-only
   here, and setup is no exception.
4. **Merge that setup PR**, then tell Claude. It pulls the default branch
   and walks you into Stage 1. The merge has to happen first: the
   `.claude/.bootstrapped` marker must be tracked and reachable from the
   default branch, or parallel worktrees look unconfigured and re-bootstrap
   themselves, and any branch you fork before the merge carries the whole
   scaffold in its diff.
5. **You're in the loop.** Bootstrap shows the six-stage map, asks what you
   want to build first, and creates and commits your first
   `intent/<slug>.md` on a new branch with you.
6. *(Optional)* set the `ANTHROPIC_API_KEY` secret on the new GitHub repo
   (Settings → Secrets → Actions) so `.github/workflows/agent-evals.yml`
   and the PR review workflow can run. Without it both skip cleanly and
   explain themselves in the run summary — your PRs stay green, they just
   don't get automated review until you opt in.
7. *(Optional)* **Trim or extend `.claude/skills/`** for anything
   project-specific beyond what bootstrap covers — org brand, compliance,
   or UX policies.
8. *(Recommended)* **turn on branch protection** for the default branch —
   require a PR and an approving review. `default-branch-guard.sh` enforces
   the same rule for Claude sessions in this repo, but only the server side
   binds everyone, including humans at their own terminal. Note that on
   github.com this needs a public repo or a paid plan; on a free private
   repo the hook is the only enforcement you get.

Bootstrap deliberately leaves `bands.yaml`, `evals/examples/`, and the
`intent/`/`design/`/`plans/` templates alone — those fill in from real use,
not initial setup.

### Maintaining this skeleton itself

This repo needs to be marked as a **GitHub template repository** for step 1
above to work: `gh repo edit <owner>/<repo> --template`, or Settings →
General → check "Template repository". One-time setup, done once this repo
is pushed.

## Starting your first piece of work

The short version: **run `/sdlc`** and Claude tells you where the current
branch stands and what to do next, at any point in the cycle. The long
version is below, once, so you know what it's driving.

One slug threads through everything — pick a short kebab-case name for the
initiative (e.g. `csv-export`) and reuse it as the branch name and every
artifact's filename. Each step's *unlock* is what makes the next step legal;
don't start a stage whose upstream artifact still says `status: draft`.

1. `git checkout -b <slug>` from the default branch.
2. **Stage 1.** Copy `intent/TEMPLATE.md` → `intent/<slug>.md`, fill it in
   (talk it through with Claude if useful), commit.
   *Unlock:* a product owner reviews it and sets `status: approved`.
3. **Stage 2.** Ask Claude to draft `design/<slug>.spec.md` from the approved
   intent. Policy skills apply here — anything they raise lands under **Policy
   flags** and goes to that policy's owner. Review, adjust, commit.
   *Unlock:* flags resolved and the product owner sets `status: approved`.
4. **Stage 3.** Start a Claude Code session in **plan mode** referencing the
   spec and iterate until the plan's right — see `plans/README.md` for the
   exact steps — then commit it as `plans/<slug>.plan.md`.
   *Unlock:* the plan is committed. Nothing gets implemented before that.
5. **Stages 3–4.** Switch to auto mode, implement, and verify against
   `CLAUDE.md`'s commands. Then hand the change to the `verifier` subagent,
   which checks the diff against the plan with fresh context.
   *Unlock:* verification passes and `verifier` reports PASS.
6. **Stage 5.** Push, open a PR. `REVIEW.md`'s four passes apply here — run
   `/code-review` yourself before or instead of waiting on the GitHub Action
   if you want the feedback sooner.
   *Unlock:* a human approves the merge. Claude's findings are advisory.
7. **Stage 6.** Merge. If this was a bug fix, the regression test that proved
   it belongs in `evals/` too — see `evals/README.md`. From here, a breached
   control band in `bands.yaml` writes the next `intent/*.md` on its own.

Working on more than one of these at a time? See the `worktree` skill
(`.claude/skills/worktree/SKILL.md`) instead of switching branches in
place.

## Repository layout

| Path | Stage | Purpose |
|---|---|---|
| `intent/` | 1. Plan | Problem framing, one file per initiative |
| `design/` | 2. Design | Requirements + design spec derived from an intent |
| `plans/` | 3. Build | Implementation plans (usually one per branch/PR, committed for audit trail) |
| `CLAUDE.md` | 3. Build | Institutional knowledge Claude reads every session |
| `.claude/skills/` | 2–3 | Triggered policy skills (brand, security, compliance, UX) |
| `.claude/skills/sdlc/` | all | `/sdlc` — reports which stage the branch is in and drives the next handoff |
| `.claude/hooks/` | 3, 5 | Deterministic guardrails and approval gates |
| `.claude/agents/` | 3 | Subagents for repeated tasks (verification, review, research) |
| `.claude/settings.json` | 3, 5 | Wires hooks into tool events |
| `evals/` | 4. Test | Regression tests for agent configuration itself |
| `.github/workflows/agent-evals.yml` | 4, 5 | CI that runs evals when `CLAUDE.md`/`.claude/` change |
| `REVIEW.md` | 5. Deploy | PR review policy Claude applies to every change |
| `bands.yaml` | 6. Maintain | Control-band thresholds for monitoring → intent.md |

## Stage-by-stage notes

**1. Plan.** Anyone can start an `intent/*.md` by talking to Claude — no git
expertise required if you wire up a connector (e.g. via Claude or Cowork) that
commits on their behalf. A product owner reviews before it advances.

**2. Design.** Claude reads the accepted intent and drafts `design/*.md`,
constrained by whatever skills encode your policies. Flagged concerns go to
the policy owner; the product owner approves before build starts.

**3. Build.** Start every implementation in Claude Code's plan mode. Commit
the approved plan to `plans/` before writing code — that's your audit trail.
Run independent streams in separate git worktrees.

**4. Test.** Wrap verification in one command (`make test`, `npm test`, etc.)
documented in `CLAUDE.md` with expected healthy output. For bug fixes, write
and commit the failing test *before* the fix, and don't let the agent edit it
while fixing. Treat `CLAUDE.md`/`.claude/` changes like code: they get evals
in CI (see `evals/`), and every production incident becomes a permanent eval.

**5. Deploy.** `REVIEW.md` defines the four passes Claude runs on every PR
(bugs, security, compliance, simplicity). Hooks act as approval gates for anything
hard-to-reverse — production deploys, protected-path edits. If you're a
regulated org, layer in [managed
settings](https://docs.claude.com/en/docs/claude-code/settings) at the admin
console level so engineers can't override the gates.

**6. Maintain.** A monitoring script watches SLOs against the bands in
`bands.yaml`. Breaches past the top band produce a new `intent/*.md` with
anomaly evidence — closing the loop back to Stage 1. Each incident class
should also land in `evals/` as a regression test.

## What this skeleton deliberately leaves out

- No language/stack is assumed — commands in `CLAUDE.md` and hook scripts are
  placeholders you fill in.
- No production monitoring script is included (Stage 6's detection script is
  specific to your metrics stack) — `bands.yaml` just defines the shape.
- No license file — add one before making the repo public if you intend
  others to reuse it.
