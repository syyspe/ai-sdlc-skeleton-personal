# plans/ — Stage 3: Build

One plan per branch/PR, named to match: `design/foo.spec.md` →
`plans/foo.plan.md`. This is the audit trail for "nothing gets implemented
without a written plan."

Workflow:

1. Start a Claude Code session in **plan mode** with the relevant
   `design/*.spec.md` open.
2. Claude proposes a plan: affected files, work order, tests to add/update.
3. Iterate on the plan with Claude before any code is generated.
4. Once approved, commit it here as `<name>.plan.md`.
5. Switch to auto mode and implement. The merged diff should match this
   plan — Stage 5 review checks that.

Copy `TEMPLATE.plan.md` to get started. For independent parallel streams,
use the `worktree` skill (`.claude/skills/worktree/SKILL.md`) instead of
switching branches in place.

**Done when:** the plan is committed and an engineer who has never seen the
conversation could implement the change from it alone. If implementation
departs from the plan, update the plan in the same commit.

**Next:** Stage 4 (Test) — run the verification command from `CLAUDE.md`,
then hand the change to the `verifier` subagent, which re-checks the diff
against this plan with fresh context. Then Stage 5: `/code-review`, push,
PR. Run `/sdlc` if you're unsure where a branch stands.
