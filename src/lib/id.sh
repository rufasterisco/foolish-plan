#!/bin/bash
# ID generation for koh issues.
# Scans git branches matching the pattern <number>-<slug> and returns
# the next sequential number.

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
