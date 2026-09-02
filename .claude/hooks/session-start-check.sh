#!/usr/bin/env bash
# SessionStart hook, two jobs:
#
#   1. Unconfigured clone (no .claude/.bootstrapped) — push the session into
#      the bootstrap skill.
#   2. Configured repo — report where the current branch stands in the SDLC
#      loop and what the next action is. The stage is derived from the
#      artifact chain itself (which of intent/design/plans exist for the
#      branch slug, and their "status:" frontmatter), never from separate
#      state. That's the playbook's automated handoff: an approved intent
#      unlocks design, an approved spec unlocks plan mode.
#
# Both paths only inject context — this hook never blocks anything, and any
# probe that can't run (no git, missing dirs) falls back to silence.

set -euo pipefail
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

if [ ! -f .claude/.bootstrapped ]; then
  cat <<'EOF'
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "This is an unconfigured clone of the ai-sdlc-skeleton (no .claude/.bootstrapped marker). Start the bootstrap flow immediately in your first message: a one-line intro plus the first question (project name and purpose) in the same message — don't ask permission to begin, and don't bundle further questions in with it. Follow .claude/skills/bootstrap/SKILL.md exactly: one question at a time, waiting for each reply, including its tech-stack scaffolding step."}}
EOF
  exit 0
fi

HOWTO="Orientation, not a script to recite: if the user opens with something \
open-ended (what next, let's continue, hi), lead with the stage and next \
action in at most two lines. Otherwise hold this as context and answer what \
was asked. The sdlc skill has the full loop map and the exact commands."

emit() {
  MSG="$1" python3 -c 'import json, os
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": os.environ["MSG"],
}}))'
  exit 0
}

# Frontmatter "status:" value of an artifact, or empty if absent/unreadable.
status_of() {
  sed -n '1,12s/^status:[[:space:]]*\([a-z]*\).*/\1/p' "$1" 2>/dev/null | head -1
}

checklist_line() {
  if [ -f "$1" ]; then
    printf '  [x] %-34s %s\n' "$1" "$(status_of "$1")"
  else
    printf '  [ ] %s\n' "$1"
  fi
}

slug=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
[ -n "$slug" ] || exit 0

case "$slug" in
  main | master | HEAD)
    emit "SDLC loop: on the default branch ($slug) — no work stream checked out.

Next: Stage 1 (Plan). Pick a short kebab-case slug for the initiative, run
git checkout -b <slug>, then fill intent/<slug>.md from intent/TEMPLATE.md.
That one slug names the branch and every downstream artifact.

$HOWTO"
    ;;
esac

intent="intent/$slug.md"
spec="design/$slug.spec.md"
plan="plans/$slug.plan.md"

if [ ! -f "$intent" ] && [ ! -f "$spec" ] && [ ! -f "$plan" ] && [ ! -d intent ]; then
  exit 0  # not a skeleton layout (or the dirs were removed) — say nothing
fi

chain=$(
  checklist_line "$intent"
  checklist_line "$spec"
  checklist_line "$plan"
)

if [ ! -f "$intent" ]; then
  stage="Stage 1 (Plan) — not started."
  next="copy intent/TEMPLATE.md to $intent and fill it in with the user
(Problem, Proposed outcome, Affected systems, Constraints, Open questions),
then commit it. Committing an approved intent is what unlocks Stage 2."
elif [ "$(status_of "$intent")" != "approved" ]; then
  stage="Stage 1 (Plan) — intent drafted, not yet approved."
  next="the product owner reviews $intent and signs off. Once its frontmatter
reads status: approved and that is committed, Stage 2 (Design) is unlocked.
Don't draft the spec before then."
elif [ ! -f "$spec" ]; then
  stage="Stage 2 (Design) — intent approved, spec not started."
  next="draft $spec from the approved intent using design/TEMPLATE.spec.md.
Policy skills in .claude/skills/ apply here — record anything they raise under
Policy flags. Review with the user, then commit."
elif [ "$(status_of "$spec")" != "approved" ]; then
  stage="Stage 2 (Design) — spec drafted, not yet approved."
  next="resolve the spec's Policy flags with the relevant policy owner, get
product-owner approval, then set $spec to status: approved and commit. That
unlocks Stage 3 (Build)."
elif [ ! -f "$plan" ]; then
  stage="Stage 3 (Build) — spec approved, no plan yet."
  next="start in plan mode against $spec and iterate until an engineer who has
never seen the conversation could implement from the plan alone. Commit it as
$plan BEFORE writing any code — that's the audit trail Stage 5 review checks
the diff against."
elif [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  stage="Stage 3 (Build) → Stage 4 (Test) — plan committed, work in progress."
  next="finish the plan's work order, then run the verification command from
CLAUDE.md and hand the change to the verifier subagent before any human sees
it. If implementation departed from the plan, update $plan in the same commit."
else
  stage="Stage 3 (Build) — plan committed, working tree clean."
  next="implement $plan's work order, or if it's already implemented and
committed, move to Stage 5: run /code-review (REVIEW.md's four passes), push,
and open a PR for human approval."
fi

emit "SDLC loop — branch: $slug

$chain

$stage
Next: $next

$HOWTO"
