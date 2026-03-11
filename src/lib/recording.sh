#!/bin/bash
# Recording extraction for koh.
# Finds Claude Code session logs, scrubs secrets, and copies them to a destination.

# Encode a directory path the way Claude Code does for its project dirs.
# /Users/me/projects/foo -> -Users-me-projects-foo
encode_project_dir() {
  local abs_dir
  abs_dir=$(cd "$1" && pwd)
  echo "$abs_dir" | tr '/.' '--'
}

# Get the session log directory for a working directory.
session_log_dir() {
  local working_dir="$1"
  local encoded
  encoded=$(encode_project_dir "$working_dir")
  echo "$HOME/.claude/projects/$encoded"
}

# Scrub secrets from a file using gitleaks.
# Detects secrets, then replaces each one with [REDACTED] in-place.
scrub_recording() {
  local file="$1"

  if ! command -v gitleaks >/dev/null 2>&1; then
    echo "ERROR: gitleaks is required for recording extraction (brew install gitleaks)" >&2
    return 1
  fi

  local report
  report=$(mktemp)

  # Scan the file for secrets (exit code 1 = secrets found, not an error)
  gitleaks detect --source "$file" --report-format json --report-path "$report" --no-git --max-decode-depth 3 2>/dev/null || true

  # Check if any secrets were found
  local count
  count=$(jq 'length' "$report" 2>/dev/null || echo "0")

  if [ "$count" -eq 0 ]; then
    rm -f "$report"
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
  rm -f "$report"
  echo "Secrets scrubbed."
}

# Snapshot current .jsonl files in the session log directory.
# Writes the list to a file. Returns the snapshot file path.
snapshot_recordings() {
  local working_dir="$1"
  local snapshot_file="$2"

  local dir
  dir=$(session_log_dir "$working_dir")

  local files=()
  for f in "$dir"/*.jsonl; do
    [ -e "$f" ] && files+=("$f")
  done
  printf '%s\n' "${files[@]}" | sort > "$snapshot_file"
}

# Extract all recordings for a working directory.
# Concatenates all .jsonl files into dest, then scrubs.
extract_all_recordings() {
  local working_dir="$1"
  local dest="$2"

  local dir
  dir=$(session_log_dir "$working_dir")

  local files=()
  for f in "$dir"/*.jsonl; do
    [ -e "$f" ] && files+=("$f")
  done

  if [ ${#files[@]} -eq 0 ]; then
    echo "No session logs found." >&2
    return 1
  fi

  > "$dest"
  local sorted
  sorted=$(printf '%s\n' "${files[@]}" | sort)
  while IFS= read -r f; do
    cat "$f" >> "$dest"
  done <<< "$sorted"

  if ! scrub_recording "$dest"; then
    rm -f "$dest"
    return 1
  fi
}

# Extract recordings that are new since a snapshot.
# Concatenates all new .jsonl files into dest, then scrubs.
extract_new_recordings() {
  local working_dir="$1"
  local snapshot_file="$2"
  local dest="$3"

  local dir
  dir=$(session_log_dir "$working_dir")

  local current
  current=$(mktemp)
  local cur_files=()
  for f in "$dir"/*.jsonl; do
    [ -e "$f" ] && cur_files+=("$f")
  done
  printf '%s\n' "${cur_files[@]}" | sort > "$current"

  # Diff: files in current but not in snapshot
  local new_files
  new_files=$(comm -23 "$current" "$snapshot_file")
  rm -f "$current"

  if [ -z "$new_files" ]; then
    echo "No new session logs found." >&2
    return 1
  fi

  # Concatenate all new files (sorted by name, which is chronological)
  > "$dest"
  while IFS= read -r f; do
    cat "$f" >> "$dest"
  done <<< "$new_files"

  if ! scrub_recording "$dest"; then
    rm -f "$dest"
    return 1
  fi
}
