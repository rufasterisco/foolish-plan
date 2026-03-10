# ID generation — implementation proposal

## What it is

A single function/script that returns the next issue ID. All other scripts call this — nothing else generates IDs. This makes the strategy swappable (sequential, date-based, UUID, external) without changing the rest of the system.

## Interface

```sh
# called by other scripts
next_id=$(koh/bin/next-id)
# returns: 4
```

## Strategy: sequential

- Scan `koh/issues/` for existing folders
- Each folder starts with `<number>-` (e.g. `3-add-auth`)
- Extract the numbers, find the highest, return highest + 1
- If no folders exist, return 1

## Steps

### Step 1: scan existing issues

- `ls koh/issues/` and extract leading numbers
- Handle: empty directory, non-numeric folders (skip them), gaps in sequence (don't fill — just use max + 1)

### Step 2: return next number

- `echo $((max + 1))`

## Implementation

A shell function in a shared library file that other scripts source. Something like:

```sh
# koh/lib/id.sh
next_id() {
  local issues_dir="$1"
  local max=0
  for dir in "$issues_dir"/*/; do
    num=$(basename "$dir" | grep -oE '^[0-9]+' || true)
    if [ -n "$num" ] && [ "$num" -gt "$max" ]; then
      max="$num"
    fi
  done
  echo $((max + 1))
}
```

## Open questions

1. **Concurrency** — two `/think` calls at the same time could get the same ID. Acceptable for now? Could use a lock file later.
2. **Where does it scan?** — the main repo's `koh/issues/`, or the worktree's? Since worktrees branch off, the main repo has the most complete view. But branches might have issues not yet merged. Probably scan main repo.
