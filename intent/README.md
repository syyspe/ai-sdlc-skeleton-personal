# intent/ — Stage 1: Plan

One file per initiative, named `<short-slug>.md`. Anyone on the team can
start one by talking through the idea with Claude — no git or engineering
expertise required if a connector is wired up to commit on their behalf.

Copy `TEMPLATE.md` to get started. A product owner reviews and approves
before it advances to Stage 2 (Design).

The slug also names the branch (`git checkout -b <slug>`) and every
downstream artifact (`design/<slug>.spec.md`, `plans/<slug>.plan.md`) —
see the root `README.md`'s "Starting your first piece of work" for the
full recipe end to end.

Control-band breaches from `bands.yaml` (Stage 6) also land here
automatically, in the same format, closing the monitoring loop back to
Stage 1.

**Done when:** the intent answers all five sections honestly (thin is fine;
invented constraints are not), a product owner has signed off, and its
frontmatter reads `status: approved` — committed.

**Next:** Stage 2 (Design). Claude drafts `design/<slug>.spec.md` from the
approved intent. Nothing downstream starts while this file still says
`status: draft`. Run `/sdlc` if you're unsure where a branch stands.
