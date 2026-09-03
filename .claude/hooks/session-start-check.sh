#!/usr/bin/env bash
# SessionStart hook, two jobs:
#
#   1. Unconfigured clone (no .claude/.bootstrapped) — push the session into
#      the bootstrap skill.
#   2. Configured repo — report where the current branch stands in the loop
#      and what the next action is. The stage is derived from the artifact
#      chain itself — which of brief/plan exist for the branch slug, and
#      whether code has landed since the plan commit — never from separate
#      state and never from an approval flag: an artifact exists or it
#      doesn't. Every boundary in the loop is computable here, which is why
#      verification lives at the head of Stage 4 rather than the tail of
#      Stage 3: "has it been verified?" is the one question a fresh session
#      cannot answer off disk, so no boundary is allowed to depend on it.
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

checklist_line() {
  if [ -f "$1" ]; then
    printf '  [x] %s\n' "$1"
  else
    printf '  [ ] %s\n' "$1"
  fi
}

slug=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
[ -n "$slug" ] || exit 0

case "$slug" in
  main | master | HEAD)
    emit "Loop status: on the default branch ($slug) — no work stream checked out.

Next: Stage 1 (Brief). Pick a short kebab-case slug, run git checkout -b
<slug>, then write brief/<slug>.md from brief/TEMPLATE.md. That one slug names
the branch and the plan that follows it.

$HOWTO"
    ;;
esac

brief="brief/$slug.md"
plan="plans/$slug.plan.md"

if [ ! -f "$brief" ] && [ ! -f "$plan" ] && [ ! -d brief ]; then
  exit 0  # not a skeleton layout (or the dirs were removed) — say nothing
fi

# Has code landed since the plan was committed? Dated from the commit that
# ADDED the plan, not the last one to touch it — a build session is told to
# amend the plan in the same commit as the code it drifted from, and dating
# from that would hide the very code it's meant to detect.
code=""
if [ -f "$plan" ]; then
  plan_commit=$(git log --diff-filter=A --format=%H -1 -- "$plan" 2>/dev/null)
  if [ -n "$plan_commit" ]; then
    code=$(git log --format=%H "$plan_commit"..HEAD -- . \
      ':(exclude)brief' ':(exclude)plans' 2>/dev/null)
  fi
fi

chain=$(
  checklist_line "$brief"
  checklist_line "$plan"
  if [ -n "$code" ]; then
    printf '  [x] code committed\n'
  else
    printf '  [ ] code committed\n'
  fi
)

if [ ! -f "$brief" ]; then
  stage="Stage 1 (Brief) — not started."
  next="write $brief from brief/TEMPLATE.md with the user (Problem, What done
looks like, Approach, Out of scope, Open questions), then commit it. Keep it
thin — a short honest brief beats a padded one. There's no approval step; the
commit is the handoff to Stage 2."
elif [ ! -f "$plan" ]; then
  stage="Stage 2 (Plan) — brief committed, no plan yet."
  next="call the EnterPlanMode tool now, as your first action — don't wait to
be asked and don't assume the user started the session in plan mode. Then read
$brief and iterate on the approach until it could be implemented from the file
alone. Once ExitPlanMode is approved, write the plan to $plan from
plans/TEMPLATE.plan.md and commit it BEFORE any code — that commit is the audit
trail Stage 4 review checks the diff against. Then stop: the commit ends the
stage. Approving ExitPlanMode approves the plan, not a go-ahead to build now —
don't start the work order in this session. Say the plan is committed, name its
first step, and suggest picking Build up in a fresh session with /model
sonnet."
elif [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  stage="Stage 3 (Build) — plan committed, work in progress."
  next="finish $plan's work order and commit it. If the implementation departed
from the plan, update $plan in the same commit. The commit ends the stage —
verification, the verifier subagent, /code-review and the PR are all Stage 4,
in a fresh session. Don't run them here."
elif [ -z "$code" ]; then
  stage="Stage 3 (Build) — plan committed, no code yet."
  next="implement $plan's work order and commit it. simple-code applies from
the first line, not as a cleanup pass. That commit is this session's whole job
and the end of the stage — verification and review are Stage 4, in a fresh
session."
else
  stage="Stage 4 (Ship) — code committed since the plan."
  next="verify, then review, then ship — all in this session, in order: (1) run
the verification command from CLAUDE.md and report its real output; (2) call
the verifier subagent, which re-checks the diff against $plan with fresh
context; (3) /code-review for REVIEW.md's passes; (4) git push -u origin $slug
&& gh pr create. Steps 1-4 are one continuous sequence — don't stop between
them to ask how to proceed. If verification or the verifier fails, fixing it is
the job now; a substantial fix means going back to a Stage 3 session for it.
The user reviews the PR and merges."
fi

emit "Loop status — branch: $slug

$chain

$stage
Next: $next

$HOWTO"
