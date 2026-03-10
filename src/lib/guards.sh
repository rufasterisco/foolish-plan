#!/bin/bash
# Shared guards for koh scripts.

# Refuse to run inside a git worktree. All koh commands must run from
# the main repo checkout to avoid nested worktrees and duplicate IDs.
assert_not_worktree() {
  local git_dir git_common_dir
  git_dir=$(git rev-parse --git-dir 2>/dev/null) || {
    echo "ERROR: not inside a git repository" >&2
    return 1
  }
  git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null) || return 1

  # Resolve to absolute paths for reliable comparison
  git_dir=$(cd "$git_dir" && pwd)
  git_common_dir=$(cd "$git_common_dir" && pwd)

  if [ "$git_dir" != "$git_common_dir" ]; then
    echo "ERROR: refusing to run inside a worktree. Run from the main repo." >&2
    return 1
  fi
}

# Get the repo root (absolute path).
repo_root() {
  git rev-parse --show-toplevel
}
