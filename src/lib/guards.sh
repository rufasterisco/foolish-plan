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

# Require running inside a git worktree.
assert_is_worktree() {
  local git_dir git_common_dir
  git_dir=$(git rev-parse --git-dir 2>/dev/null) || {
    echo "ERROR: not inside a git repository" >&2
    return 1
  }
  git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null) || return 1

  # Resolve to absolute paths for reliable comparison
  git_dir=$(cd "$git_dir" && pwd)
  git_common_dir=$(cd "$git_common_dir" && pwd)

  if [ "$git_dir" = "$git_common_dir" ]; then
    echo "ERROR: must run inside a koh worktree, not the main repo." >&2
    return 1
  fi
}

# Validate that a string matches the koh id-slug format (e.g. "4-add-auth").
assert_valid_id_slug() {
  local id_slug="$1"
  if ! [[ "$id_slug" =~ ^[0-9]+-[a-z0-9-]+$ ]]; then
    echo "ERROR: '$id_slug' does not match koh naming convention (expected: <number>-<slug>)" >&2
    return 1
  fi
}

# Get the repo root (absolute path).
repo_root() {
  git rev-parse --show-toplevel
}
