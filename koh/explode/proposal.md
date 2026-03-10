# /explode (local) — implementation proposal

## What it is

A shell script + slash command that runs a coding session. It launches claude interactively inside a tmux session, pointed at an existing worktree/branch from /think. When the session ends, it captures the recording and commits it.

## Interface

```sh
# as a slash command inside claude:
/explode 4-add-auth

# or directly:
koh/bin/explode 4-add-auth
```

## Preconditions

- `/think` has already run for this issue
- Branch `<id-slug>` exists
- Worktree exists at `.koh-worktrees/<id-slug>`
- `koh/issues/<id-slug>/issue.md` exists in the worktree

## Output

The worktree's branch gets a commit with the recording:

```
<worktree>/koh/issues/<id-slug>/
  issue.md                  # already exists from /think
  think-recording.jsonl     # already exists from /think
  explode-recording.jsonl   # new — captured from this session
```

Plus whatever code changes claude made during the session (already committed by claude).

## Steps

### Step 0: worktree guard

- Refuse to run inside a worktree. All koh commands must run from the main repo checkout.
- Detection: `git rev-parse --git-common-dir` differs from `git rev-parse --git-dir` → you're in a worktree.
- Shared guard in `koh/lib/guards.sh`.

### Step 1: validate

- Check that the `<id-slug>` argument is provided
- Check that the worktree exists at `.koh-worktrees/<id-slug>`
- Check that `koh/issues/<id-slug>/issue.md` exists in the worktree

### Step 2: seed claude with -p

- `cd` into the worktree
- Run `claude -p "Read koh/issues/<id-slug>/issue.md and begin working on the execution plan" --output-format stream-json --verbose | tee <tmp-file>`
- This gives us the session ID from the output
- Claude reads the issue and produces an initial response

### Step 3: launch interactive session in tmux

- Create tmux session: `tmux new-session -d -s "koh-<id-slug>" -c "<worktree-path>" "claude --continue"`
- The `--continue` picks up the seeded session — claude already has the issue context
- User can attach with `koh/bin/tmux connect <id-slug>`

### Step 4: wait for session to end

- When claude exits, tmux session ends
- A wrapper command in tmux handles post-exit: runs the recording extraction and commit

### Step 5: extract recording

- Session ID captured from step 2's `-p` output
- Call `extract_recording` (from `koh/lib/recording.sh`)
- Copy to `<worktree>/koh/issues/<id-slug>/explode-recording.jsonl`

### Step 6: commit recording

- `cd <worktree>`
- `git add koh/issues/<id-slug>/explode-recording.jsonl`
- `git commit -m "<id-slug>: add session recording"`

## Open questions

1. **tmux post-exit** — exact mechanism for running steps 5-6 after claude exits. Wrapping the command in a script that runs inside tmux is simplest.
2. **Claude already commits** — during the session, claude commits code. The recording commit comes after. Separate commits are fine.
