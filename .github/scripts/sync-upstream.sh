#!/usr/bin/env bash
# Merges upstream into this fork. Files listed in FORK_OWNED_PATHS are owned by
# the fork: on conflict the fork's version wins. Any other conflict fails the run.
set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/obra/superpowers.git}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
FORK_OWNED_PATHS=(AGENTS.md)

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git fetch --no-tags "$UPSTREAM_URL" "$UPSTREAM_BRANCH"
upstream_sha="$(git rev-parse FETCH_HEAD)"

if git merge-base --is-ancestor "$upstream_sha" HEAD; then
  echo "Already up to date with upstream ${upstream_sha}"
  exit 0
fi

merge_message="chore: sync with upstream obra/superpowers@${upstream_sha:0:12}"
if git merge --no-ff --no-edit -m "$merge_message" "$upstream_sha"; then
  exit 0
fi

conflicted="$(git diff --name-only --diff-filter=U)"
for path in "${FORK_OWNED_PATHS[@]}"; do
  if grep -qxF -- "$path" <<<"$conflicted"; then
    git checkout --ours -- "$path"
    git add -- "$path"
  fi
done

remaining="$(git diff --name-only --diff-filter=U)"
if [ -n "$remaining" ]; then
  echo "::error::Upstream conflicts with fork changes; resolve manually:"
  echo "$remaining"
  git merge --abort
  exit 1
fi

git commit --no-edit
