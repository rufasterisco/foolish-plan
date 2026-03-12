#!/bin/bash
# ID generation for koh issues.
# Scans git branches matching the pattern <number>-<slug> and returns
# the next sequential number.

# Returns a tmux-safe repo prefix derived from the git toplevel directory name.
# Lowercased, only alphanumeric and hyphens, no leading/trailing hyphens.
repo_prefix() {
  local name
  name=$(basename "$(git rev-parse --show-toplevel)")
  # Lowercase, replace non-alphanumeric with hyphens, collapse multiple hyphens, strip leading/trailing
  echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//'
}

next_id() {
  local max=0
  local num
  local branch
  for branch in $(git branch --list '[0-9]*-*' --format='%(refname:short)' 2>/dev/null); do
    num=$(echo "$branch" | grep -oE '^[0-9]+' || true)
    if [ -n "$num" ] && [ "$num" -gt "$max" ]; then
      max="$num"
    fi
  done
  echo $((max + 1))
}
