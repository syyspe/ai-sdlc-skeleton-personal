# .claude/skills/ — policy encoding

Skills here are triggered automatically during Stage 2 (Design) and Stage 3
(Build) to apply organizational policy consistently — brand, security,
compliance, UX. They're advisory controls: they make correct behavior
likely, unlike hooks (`.claude/hooks/`) which make violations impossible.

`secure-api-review/` and `simple-code/` are filled-out examples of that.
Three others aren't policy — they drive the process itself: `sdlc/` (`/sdlc`
— which stage the branch is in and what's next), `bootstrap/` (one-time
project setup), and `worktree/` (parallel work streams).

Add more folders following the same shape — one directory per skill,
containing a `SKILL.md` with frontmatter describing when it triggers.

When a policy changes, update the skill here once; it applies everywhere
this repo is used from that point on.
