#!/usr/bin/env bash
# Minimal eval harness: runs every evals/examples/*.json prompt against
# Claude non-interactively in a disposable copy of the repo, then runs its
# command checks. "manual" checks are printed for a human (or LLM-judge job)
# to score separately — this script doesn't attempt to auto-grade those.
#
# Usage: evals/run.sh
# Exit code: 0 if all command checks pass (or everything was skipped), 1 if
# any fail.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLES_DIR="$REPO_ROOT/evals/examples"
FAILED=0
RAN=0
SKIPPED=0

# Order matters: if there's no key there's nothing to run, so don't nag about
# tooling first.
if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  echo "SKIP: no ANTHROPIC_API_KEY (or CLAUDE_CODE_OAUTH_TOKEN) in the"
  echo "environment, so 'claude -p' can't authenticate. Set one to run evals."
  exit 0
fi

if ! command -v jq > /dev/null; then
  echo "jq is required to parse evals/examples/*.json — install it and re-run." >&2
  exit 1
fi

for eval_file in "$EXAMPLES_DIR"/*.json; do
  id=$(jq -r '.id' "$eval_file")
  description=$(jq -r '.description' "$eval_file")
  prompt=$(jq -r '.prompt' "$eval_file")

  echo "=== $id ==="
  echo "$description"

  # An eval still carrying <placeholder> text is a template, not a test —
  # its prompt names files that don't exist. Skip rather than fail, so a
  # fresh clone of the skeleton has green CI until real evals are written.
  if grep -q '<[a-z][^>]*>' "$eval_file"; then
    echo "  [SKIP] still a template — replace the <placeholders> to enable it"
    SKIPPED=$((SKIPPED + 1))
    echo
    continue
  fi

  workdir=$(mktemp -d)
  # Copy the repo (tracked files only) into a disposable sandbox so the run
  # can't leave state behind or touch anything outside itself.
  git -C "$REPO_ROOT" archive HEAD | tar -x -C "$workdir"

  # git archive produces plain files, no .git — so make the sandbox a repo of
  # its own, with the pre-run state as its first commit. Checks can then use
  # git diff/status to see exactly what the agent changed, without ever
  # reaching outside the sandbox.
  git -C "$workdir" init -q
  git -C "$workdir" add -A
  git -C "$workdir" \
    -c user.email=evals@localhost -c user.name="eval harness" \
    commit -qm "pre-eval state"

  RAN=$((RAN + 1))
  ( cd "$workdir" && claude -p "$prompt" --permission-mode acceptEdits ) \
    || { echo "  claude invocation failed for $id"; FAILED=1; }

  checks_len=$(jq '.checks | length' "$eval_file")
  for i in $(seq 0 $((checks_len - 1))); do
    type=$(jq -r ".checks[$i].type" "$eval_file")
    if [ "$type" = "command" ]; then
      cmd=$(jq -r ".checks[$i].command" "$eval_file")
      if ( cd "$workdir" && eval "$cmd" ); then
        echo "  [PASS] command check $i"
      else
        echo "  [FAIL] command check $i: $cmd"
        FAILED=1
      fi
    elif [ "$type" = "manual" ]; then
      criteria=$(jq -r ".checks[$i].criteria" "$eval_file")
      echo "  [MANUAL] $criteria (needs human or LLM-judge review — see $workdir)"
    fi
  done

  echo
done

echo "ran: $RAN, skipped: $SKIPPED"
exit $FAILED
