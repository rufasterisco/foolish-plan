# ID generation — implementation proposal

## What it is

A single function/script that returns the next issue ID. All other scripts call this — nothing else generates IDs. This makes the strategy swappable (sequential, date-based, UUID, external) without changing the rest of the system.

## Interface

```sh
# called by other scripts
source koh/lib/id.sh
next_id
# returns: 4
```

## Strategy: sequential, branch-based

- Scan git branches matching the koh pattern: `<number>-<slug>`
- Extract the numbers, find the highest, return highest + 1
- If no matching branches exist, return 1
- Branches are the source of truth — they exist even before issue files are merged to main

## Steps

### Step 1: scan branches

- `git branch --list '[0-9]*-*'` to find koh-pattern branches
- Extract the leading number from each branch name
- Handle: non-matching branches (skip), gaps in sequence (don't fill — just use max + 1)

### Step 2: return next number

- `echo $((max + 1))`

## Implementation

```sh
# koh/lib/id.sh
next_id() {
  local max=0
  local num
  for branch in $(git branch --list '[0-9]*-*' --format='%(refname:short)'); do
    num=$(echo "$branch" | grep -oE '^[0-9]+' || true)
    if [ -n "$num" ] && [ "$num" -gt "$max" ]; then
      max="$num"
    fi
  done
  echo $((max + 1))
}
```

## Open questions

1. **Concurrency** — two `/think` calls at the same time could get the same ID. Acceptable for now (single machine, single user).
