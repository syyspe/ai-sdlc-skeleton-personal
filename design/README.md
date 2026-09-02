# design/ — Stage 2: Design

One spec per approved intent, named to match: `intent/foo.md` →
`design/foo.spec.md`. Claude drafts this by reading the accepted intent,
constrained by whatever policy skills apply (`.claude/skills/` — brand,
security, compliance, UX). Concerns a skill flags go to the relevant policy
owner for review before engineering starts; the product owner approves
before Stage 3 (Build) begins.

Copy `TEMPLATE.spec.md` to get started.

**Done when:** requirements are enumerated (not prosed), every concern a
policy skill raised is recorded under **Policy flags** with how it was
resolved, the product owner has approved, and the frontmatter reads
`status: approved` — committed.

**Next:** Stage 3 (Build). Open a session in plan mode against this spec and
commit `plans/<slug>.plan.md` before any code is written. Run `/sdlc` if
you're unsure where a branch stands.
