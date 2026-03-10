# Recording extraction — implementation proposal

## What it is

A shared function that, given a session ID and a working directory, finds the Claude Code session log and copies it to a destination. Used by both /think and /explode.

## Interface

```sh
source koh/lib/recording.sh

# with a known session ID (explode):
extract_recording <session_id> <working_dir> <destination_path>

# with newest session (think, where we don't have the session ID):
extract_latest_recording <working_dir> <destination_path>
```

## Steps

### Step 1: encode project directory

- Claude Code stores session logs in `~/.claude/projects/<encoded-dir>/`
- Encoding: absolute path with `/` replaced by `-` (confirmed via testing)
- e.g. `/Users/me/projects/foo` → `-Users-me-projects-foo`

### Step 2: locate session file

- By session ID: `~/.claude/projects/<encoded-dir>/<session-id>.jsonl`
- By newest: `ls -t <dir>/*.jsonl | head -1`
- Verify the file exists

### Step 3: copy to destination

- `cp <source> <destination>`

## Implementation

```sh
# koh/lib/recording.sh

encode_project_dir() {
  local abs_dir
  abs_dir=$(cd "$1" && pwd)
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
```

## Open questions

1. **Container extraction** — for YOLOS mode (later), we'll need to `docker cp` from the container's `~/.claude/projects/`. Not needed now.
