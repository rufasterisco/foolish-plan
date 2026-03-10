#!/bin/bash
# Recording extraction for koh.
# Finds Claude Code session logs, scrubs secrets, and copies them to a destination.

# Encode a directory path the way Claude Code does for its project dirs.
# /Users/me/projects/foo -> -Users-me-projects-foo
encode_project_dir() {
  local abs_dir
  abs_dir=$(cd "$1" && pwd)
  echo "$abs_dir" | tr '/' '-'
}

# Scrub secrets from a file using gitleaks.
# Detects secrets, then replaces each one with [REDACTED] in-place.
scrub_recording() {
  local file="$1"

  if ! command -v gitleaks >/dev/null 2>&1; then
    echo "WARNING: gitleaks not installed, skipping secret scrubbing" >&2
    return 0
  fi

  local report
  report=$(mktemp)
  trap "rm -f $report" RETURN

  # Scan the file for secrets (exit code 1 = secrets found, not an error)
  gitleaks detect --source "$file" --report-format json --report-path "$report" --no-git 2>/dev/null || true

  # Check if any secrets were found
  local count
  count=$(jq 'length' "$report" 2>/dev/null || echo "0")

  if [ "$count" -eq 0 ]; then
    return 0
  fi

  echo "Scrubbing $count secret(s) from recording..."

  # Extract unique secrets and replace each one
  local secrets
  secrets=$(jq -r '.[].Secret' "$report" | sort -u)

  local tmp
  tmp=$(mktemp)

  cp "$file" "$tmp"
  while IFS= read -r secret; do
    [ -z "$secret" ] && continue
    # Use awk for literal string replacement (no regex escaping issues)
    awk -v s="$secret" -v r="[REDACTED]" '{gsub(s, r)}1' "$tmp" > "$tmp.out"
    mv "$tmp.out" "$tmp"
  done <<< "$secrets"

  mv "$tmp" "$file"
  echo "Secrets scrubbed."
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
  scrub_recording "$dest"
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
  scrub_recording "$dest"
}
