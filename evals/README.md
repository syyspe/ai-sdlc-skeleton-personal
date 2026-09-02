# evals/ — Stage 4: regression tests for agent configuration

`CLAUDE.md`, `.claude/skills/`, and `.claude/hooks/` are configuration, and
configuration regresses just like code. Evals catch that: they're a set of
real tasks with expected outcomes, run non-interactively whenever this
configuration changes.

## How this works

1. **Collect real tasks.** Each `examples/*.json` file is one task: a prompt
   (as if a developer asked Claude to do it) and acceptance criteria (tests
   pass, lint clean, a specific behavior happens, a specific policy is
   followed).
2. **Add every production incident.** When something goes wrong in
   production because Claude did (or didn't do) something, write an eval
   that reproduces the scenario and asserts the correct behavior. This is
   the single highest-value source of evals — it directly prevents repeat
   incidents.
3. **Run in CI** on a schedule and whenever `CLAUDE.md` or `.claude/**`
   changes (see `.github/workflows/agent-evals.yml`). A regression blocks
   the config change from merging.
4. **Target 20-50 tasks** as a starting size — enough to catch real
   regressions without the suite becoming a maintenance burden itself.

## Eval file format

See `examples/incident-001.json` for a filled-out example. Shape:

```json
{
  "id": "incident-001",
  "description": "<what this guards against, and why — link the incident if there is one>",
  "prompt": "<the task, as given to Claude non-interactively>",
  "checks": [
    { "type": "command", "command": "<shell command that must exit 0>" },
    { "type": "manual", "criteria": "<something a reviewer/LLM-judge checks>" }
  ]
}
```

`run.sh` is a minimal harness: it iterates `examples/*.json`, runs the prompt
through `claude -p` non-interactively, and runs each check. Adapt it to
however your CI actually wants to score results (pass rate, blocking
threshold, etc).

### Writing checks

Each eval runs in a disposable sandbox — the repo's tracked files, extracted
with `git archive`, then `git init`ed and committed as "pre-eval state". So
inside a check, **git means "what did the agent change"**:

```
test -n "$(git status --porcelain)"                 # it did something
! git status --porcelain | grep -qE 'package\.json$' # and not that
```

Use `git status --porcelain` rather than `git diff` — it catches files the
agent *created*, which `git diff` alone misses. Write the "must not" checks
as a negated grep (`! ... | grep -q`); an un-negated `grep -v` passes as soon
as any one file is innocent, which lets "fixed the bug *and* bumped the
dependency" through. Nothing a check does can reach outside the sandbox.

### When evals don't run

Two clean skips, both exit 0, so a fresh clone isn't red before it has
anything real to test:

- **No `ANTHROPIC_API_KEY`** (or `CLAUDE_CODE_OAUTH_TOKEN`) — `claude -p`
  has nothing to authenticate with. The CI workflow skips too, and says so
  in the run summary.
- **An eval still containing `<placeholders>`** — that's a template, not a
  test; its prompt names files that don't exist. Replace them to switch it
  on.

`jq` is required, and is a hard failure rather than a skip.

## Where this sits in the loop

**Done when:** the change's own verification command passes (Stage 4 proper),
and — if this change touched `CLAUDE.md` or `.claude/**` — the eval suite
passes in CI.

**Next:** Stage 5 (Deploy) — `/code-review`, push, PR, human approval.

**Coming back the other way:** every Stage 6 incident should land here as a
permanent eval, so the same failure can't recur. That's the loop closing:
`bands.yaml` breach → `intent/*.md` → fix → regression test back in `evals/`.

Running the suite locally needs `jq` (CI installs it itself).
