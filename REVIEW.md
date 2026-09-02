# Review Policy

This file defines the review passes Claude runs on every pull request (Stage
5 of the AI-native SDLC). It's read by whatever review automation you wire up
(a `claude -p` job, `claude-code-action`, or an interactive `/code-review`)
— keep it authoritative and specific rather than generic.

## Passes

Every PR gets four passes, in this order:

1. **Bugs** — logic errors, regressions, edge cases, off-by-ones, unhandled
   error paths. Cross-reference against `plans/<branch>.plan.md` if one
   exists: does the diff match what was planned?
2. **Security** — injection risks, authentication/authorization gaps, PII or
   secret exposure, unsafe deserialization, missing input validation. Apply
   any relevant skill in `.claude/skills/` (e.g. `secure-api-review`).
3. **Compliance** — alignment with `design/<name>.spec.md` and any org
   design/brand principles. Flag scope creep beyond what the spec describes.
4. **Simplicity** — function/file length, parameter count, nesting depth,
   and complexity within the limits in
   `.claude/skills/simple-code/SKILL.md`; flag defensive code handling
   cases that can't occur, and cleverness where a simpler version would
   read just as fast.

## Severity

- **Important** — must be resolved before merge. Bugs, security issues, and
  spec deviations are always Important.
- **Nit** — style/preference, safe to defer. Cap: **5 nits per review**. If
  there are more than 5, only surface the 5 highest-value ones.

## Excluded paths

Do not review, or review at reduced strictness:

- Generated code: `<e.g. "schemas/", "*.generated.*">`
- CI-enforced items already caught by lint/format: `<list>`
- `<other excluded paths>`

## Response loop

- PR authors can tag `@claude` on a review comment to request an automated
  fix; Claude addresses it and pushes a correction.
- If a review catches the **same class of mistake** for the second time
  across different PRs, add it to the "Things Claude gets wrong here"
  section of `CLAUDE.md` so it's caught earlier next time — during
  implementation, not review.

## Human authority

Claude's review findings are advisory. A human approves the merge, and the
default branch only moves by merged PR — `default-branch-guard.sh` blocks a
direct push, so these passes can't be skipped by pushing past them. On
anything touching a protected path or production deploy, the hooks in
`.claude/hooks/` enforce this too — see `production-gate.sh`.

Back this with branch protection on the remote where your plan allows it. A
hook binds Claude sessions in this repo; only the server side binds everyone.
