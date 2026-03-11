#!/bin/bash
# Lifecycle state management for koh issues.
# States: thinking, executing, done, merged
# Represented as dotfiles (.thinking, .executing, .done, .merged) in the issue directory.

VALID_STATES=(thinking executing done merged)

# set_state <issue-dir> <state>
# Removes any existing state file, touches the new one.
set_state() {
  local issue_dir="$1"
  local new_state="$2"

  if [ ! -d "$issue_dir" ]; then
    echo "ERROR: issue directory does not exist: $issue_dir" >&2
    return 1
  fi

  # Validate state
  local valid=false
  for s in "${VALID_STATES[@]}"; do
    if [ "$s" = "$new_state" ]; then
      valid=true
      break
    fi
  done

  if [ "$valid" = false ]; then
    echo "ERROR: invalid state '$new_state'. Must be one of: ${VALID_STATES[*]}" >&2
    return 1
  fi

  # Remove any existing state files
  for s in "${VALID_STATES[@]}"; do
    rm -f "$issue_dir/.$s"
  done

  # Touch the new state file
  touch "$issue_dir/.$new_state"
}

# get_state <issue-dir>
# Prints the current state name, or "unknown" if no state file exists.
get_state() {
  local issue_dir="$1"

  for s in "${VALID_STATES[@]}"; do
    if [ -f "$issue_dir/.$s" ]; then
      echo "$s"
      return 0
    fi
  done

  echo "unknown"
}
