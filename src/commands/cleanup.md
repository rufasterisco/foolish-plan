# /cleanup — Remove merged worktrees and tmux sessions

You are helping the user clean up koh worktrees for branches that have been merged into dev. This command must be run from the main repo (not a worktree).

## Step 1: Run cleanup

Run the cleanup script:
```
.koh/bin/cleanup
```

No arguments needed — the script detects merged branches automatically.

## Step 2: Tell the user

After the script runs, summarize what was cleaned up and what was skipped (if anything).
