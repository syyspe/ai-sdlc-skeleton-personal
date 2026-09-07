# Security policy

This is a personal-scale project skeleton — markdown, prompts, and shell
hooks. It has no runtime, no dependencies, and no users to page. Reports are
still welcome.

## Reporting a vulnerability

Use GitHub's **[private vulnerability
reporting](https://github.com/syyspe/ai-sdlc-skeleton-personal/security/advisories/new)**
(Security → Report a vulnerability). Please don't open a public issue for
anything exploitable.

It's one person maintaining this in spare time: expect an acknowledgement
within a week or so, not within hours.

## What's in scope

- The hooks in `.claude/hooks/` — they gate what Claude is allowed to do, so
  a bypass in `default-branch-guard.sh`, `protected-paths.sh`, or
  `production-gate.sh` is a real finding.
- `.github/workflows/claude-review.yml` — anything that lets an untrusted
  commenter reach the `ANTHROPIC_API_KEY` secret or the workflow's write
  permissions.

## What's not

- The hooks are guardrails against an agent's mistakes, not a sandbox against
  a hostile operator. Someone who can already run arbitrary commands on your
  machine, or edit `.claude/settings.json`, is past them by definition.
- Whatever a downstream project built from this template does with its own
  code.
