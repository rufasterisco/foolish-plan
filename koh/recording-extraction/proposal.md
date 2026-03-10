# Recording extraction — implementation proposal

## What it is

A shared function that, given a session ID and a working directory, finds the Claude Code session log and copies it to a destination. Used by both /think and /explode.

## Interface

```sh
# called by other scripts
source koh/lib/recording.sh
extract_recording <session_id> <working_dir> <destination_path>

# example:
extract_recording "7f137115-28e0-4ece-8c84-d3268b9d5e2f" \
  "/Users/me/projects/foo/.koh-worktrees/4-add-auth" \
  "/Users/me/projects/foo/.koh-worktrees/4-add-auth/koh/issues/4-add-auth/think-recording.jsonl"
```

## Steps

### Step 1: encode project directory

- Claude Code stores session logs in `~/.claude/projects/<encoded-dir>/`
- Encoding: absolute path with `/` replaced by `-`
- e.g. `/Users/me/projects/foo` → `-Users-me-projects-foo`
- Input: the working directory where claude was run
- Output: the encoded directory name

### Step 2: locate session file

- Path: `~/.claude/projects/<encoded-dir>/<session-id>.jsonl`
- Verify the file exists

### Step 3: copy to destination

- `cp <source> <destination>`
- Verify the copy succeeded

## Implementation

```sh
# koh/lib/recording.sh

encode_project_dir() {
  local dir="$1"
  local abs_dir
  abs_dir=$(cd "$dir" && pwd)
  echo "$abs_dir" | tr '/' '-'
}

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
```

## Open questions

1. **Project dir encoding** — need to verify the exact encoding. We saw `-Users-francesco-deleteme-koh-recording-test` from tests. Is it always `tr '/' '-'`? What about special characters in paths?
2. **Container extraction** — for YOLOS mode (later), we'll need to `docker cp` from the container's `~/.claude/projects/` instead. The interface stays the same but the implementation differs. Not needed now.
3. **Session ID source** — /think gets it from stream-json output. /explode (interactive) needs another way. Options: parse the session log directory for the newest file matching the timeframe, or find another way to capture the session ID from an interactive session.
