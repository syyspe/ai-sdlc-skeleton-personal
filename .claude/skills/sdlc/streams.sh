#!/usr/bin/env bash
# Prints every numbered stream and its state, one per line, tab-separated:
#
#   <slug>  done
#   <slug>  in progress  <stage, read off its branch>
#   <slug>  not started
#
# Derived from git alone, never from a status field: a plan on the default
# branch means the stream merged (done); otherwise a branch named for the
# slug means it is in progress; otherwise its brief is waiting on the default
# branch (not started). Done is checked first because a squash-merged branch
# still looks unmerged to git.
#
# Reads local refs only — run `git fetch origin` first for an up-to-date
# answer. The SessionStart hook calls this without fetching, to stay fast.
#
# Run: bash .claude/skills/sdlc/streams.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

base=origin/HEAD
if ! git rev-parse -q --verify "$base" >/dev/null; then
  base=$(git for-each-ref --format='%(refname:short)' \
    refs/heads/main refs/heads/master | head -1)
fi
[ -n "$base" ] || exit 0

slugs() {
  git ls-tree --name-only "$base" brief/ \
    | sed -nE 's#^brief/([0-9]{3}-.+)\.md$#\1#p'
  git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin \
    | sed -nE 's#^(origin/)?([0-9]{3}-.+)$#\2#p'
}

# The local branch if there is one, else the remote one; empty if neither.
branch_of() {
  git rev-parse -q --verify "refs/heads/$1" >/dev/null && { echo "$1"; return; }
  git rev-parse -q --verify "refs/remotes/origin/$1" >/dev/null && echo "origin/$1"
  return 0
}

# Same rules as session-start-check.sh, read off a ref instead of the working
# tree — so a build in progress in another worktree shows as Stage 3 until its
# code is committed.
stage_of() {
  ref=$1 slug=$2
  plan="plans/$slug.plan.md"
  if ! git cat-file -e "$ref:brief/$slug.md" 2>/dev/null; then
    echo "Stage 1 (Brief)"; return
  fi
  if ! git cat-file -e "$ref:$plan" 2>/dev/null; then
    echo "Stage 2 (Plan)"; return
  fi
  plan_commit=$(git log --diff-filter=A --format=%H -1 "$ref" -- "$plan")
  if [ -n "$(git log --format=%H -1 "$plan_commit..$ref" -- . \
    ':(exclude)brief' ':(exclude)plans')" ]; then
    echo "Stage 4 (Ship)"
  else
    echo "Stage 3 (Build)"
  fi
}

slugs | sort -u | while read -r slug; do
  if git cat-file -e "$base:plans/$slug.plan.md" 2>/dev/null; then
    printf '%s\tdone\n' "$slug"
    continue
  fi
  ref=$(branch_of "$slug")
  if [ -n "$ref" ]; then
    printf '%s\tin progress\t%s (%s)\n' "$slug" "$(stage_of "$ref" "$slug")" "$ref"
  else
    printf '%s\tnot started\n' "$slug"
  fi
done
