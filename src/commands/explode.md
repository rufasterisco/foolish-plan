# /explode — Start a coding session

You are helping the user launch a coding session for an existing koh issue. This command must be run from inside a koh worktree (created by /think).

## Step 1: Launch

Run the explode script:
```
.koh/bin/explode
```

No arguments needed — the script detects the issue from the current branch.

## Step 2: Tell the user

After the script runs, tell the user:
- The tmux session name (e.g. `koh-4-add-auth`)
- How to connect: `koh-tmux connect <id-slug>`
- How to disconnect: `ctrl+b d`
- When they're done, just `/exit` from claude inside the tmux session — the recording will be extracted and committed automatically.
