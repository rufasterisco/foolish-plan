# /explode (local) — implementation proposal

## What it is

A shell script that runs a coding session. It launches claude interactively inside a tmux session, pointed at an existing worktree/branch from /think. When the session ends, it captures the recording and commits it.

## Interface

```sh
koh/bin/explode <id-slug>

# example:
koh/bin/explode 4-add-auth
```

## Preconditions

- `/think` has already run for this issue
- Branch `<id-slug>` exists
- Worktree exists at the expected location
- `koh/issues/<id-slug>/issue.md` exists in the worktree

## Output

The worktree's branch gets a commit with the recording:

```
<worktree>/koh/issues/<id-slug>/
  issue.md                  # already exists from /think
  think-recording.jsonl     # already exists from /think
  explode-recording.jsonl   # new — captured from this session
```

Plus whatever code changes claude made during the session (already committed by claude, or staged by the script).

## Steps

### Step 1: validate

- Check that the `<id-slug>` argument is provided
- Check that the worktree exists at the expected location
- Check that `koh/issues/<id-slug>/issue.md` exists
- Read the issue file — we'll feed it to claude

### Step 2: tmux session

- Create a tmux session named `koh-<id-slug>`
- The session runs inside the worktree directory

### Step 3: launch claude

- Inside the tmux session, run claude interactively
- Pass the issue file as context: `claude --resume` or just let claude read it
- **Key question:** how do we seed claude with the issue? Options:
  - A) Start with `-p "Read koh/issues/<id-slug>/issue.md and begin working on it"`, then `--continue` interactively — but we showed this works in test A2
  - B) Just run `claude` and let the user (or a system prompt) point it at the issue
  - C) Use a CLAUDE.md or slash command that auto-loads the issue
- **Decision:** Option A. `-p` seeds the context, interactive `--continue` lets the agent work. This also gives us the session ID from the `-p` output.

### Step 4: wait for session to end

- The tmux session runs until claude exits (user types /exit or ctrl+c)
- The script either:
  - A) Blocks until the tmux session ends (monitors tmux)
  - B) Returns immediately, and a cleanup hook runs when tmux ends
- **Decision:** The script sets up tmux with a post-exit hook. When claude exits, the hook runs steps 5-6 automatically.

### Step 5: extract recording

- Use the session ID captured from step 3's `-p` output
- Call `extract_recording` (from recording extraction module)
- Copy to `koh/issues/<id-slug>/explode-recording.jsonl`

### Step 6: commit recording

- `cd <worktree>`
- `git add koh/issues/<id-slug>/explode-recording.jsonl`
- `git commit -m "<id-slug>: add session recording"`
- Note: code changes made by claude during the session should already be committed by claude itself. This commit just adds the recording.

## Open questions

1. **Session ID capture** — if we use `-p` to seed, we get the session ID. But does `--continue` (interactive) use the same session ID? Test A2 confirmed yes, but need to verify this is reliable.
2. **tmux post-exit hook** — what's the right way to run cleanup when a tmux session ends? `tmux set-hook -t <session> session-closed` or wrapping the command?
3. **Claude already commits** — during the session, claude will commit code changes. The recording commit comes after. Is this clean? Should we squash? Probably just leave it — separate commits are fine.
4. **Multiple explode sessions** — can you run /explode on the same issue twice? Should the recording be appended or versioned (explode-recording-1.jsonl, explode-recording-2.jsonl)?
