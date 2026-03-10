#!/bin/bash
# Recording extraction for koh.
# Finds Claude Code session logs and copies them to a destination.

# Encode a directory path the way Claude Code does for its project dirs.
# /Users/me/projects/foo -> -Users-me-projects-foo
encode_project_dir() {
  local abs_dir
  abs_dir=$(cd "$1" && pwd)
  echo "$abs_dir" | tr '/' '-'
}

# Extract a session log by session ID.
extract_recording() {
  local session_id="$1"
  local working_dir="$2"
  local dest="$3"

  local encoded
  encoded=$(encode_project_dir "$working_dir")
  local source="$HOME/.claude/projects/$encoded/$session_id.jsonl"

  if [ ! -f "$source" ]; then
    echo "ERROR: session log not found: $source" >&2
    return 1
  fi

  cp "$source" "$dest"
}

# Extract the most recent session log for a project directory.
extract_latest_recording() {
  local working_dir="$1"
  local dest="$2"

  local encoded
  encoded=$(encode_project_dir "$working_dir")
  local dir="$HOME/.claude/projects/$encoded"
  local source
  source=$(ls -t "$dir"/*.jsonl 2>/dev/null | head -1)

  if [ -z "$source" ]; then
    echo "ERROR: no session logs found in $dir" >&2
    return 1
  fi

  cp "$source" "$dest"
}
