# Stage 1 — Brief

Write `brief/<slug>.md` from `brief/TEMPLATE.md` by interviewing the user —
Problem, What done looks like, Approach, Out of scope, Related streams, Open
questions — one question at a time. For Related streams, `git worktree list`
shows what else is checked out.

Write what they actually said. Leave a section thin, or delete it, rather than
inventing requirements to fill it.

Commit it. That commit ends the stage.

On a `backlog-*` branch (`SKILL.md` "Which streams exist"), write as many
briefs as the user has, each under its own number, and commit them. Then,
instead of the handoff, ship the branch by Stage 4's light path — the
briefs only count once they're on the default branch.

Then hand off: `SKILL.md` "Handing off".
