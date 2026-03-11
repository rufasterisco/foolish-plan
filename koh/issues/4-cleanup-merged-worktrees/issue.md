---
id: 4-cleanup-merged-worktrees
branch: 4-cleanup-merged-worktrees
worktree: /Users/francesco/projects/koh/.koh-worktrees/4-cleanup-merged-worktrees
think-recording: ./think-recording.jsonl
explode-recording: ./explode-recording.jsonl
---

# 4-cleanup-merged-worktrees: Auto-cleanup merged worktrees and tmux sessions

## Problem
After a koh issue branch is merged into dev and pulled, the worktree and tmux session are left behind. The user has to manually:
- Kill the tmux session (not just detach — exit it)
- Remove the git worktree
- Possibly delete the local branch

This should happen automatically after pulling dev from origin.

## Context from user
- "we need to have a post merge thing"
- Pull dev from origin
- Kill any tmux sessions running for merged branches (exit, not detach)
- Worktree is no longer needed since the branch is merged into dev
- User wants to understand how git worktree cleanup works

## Key questions for think session
- Should this be a git post-merge hook, a standalone script, or part of a `koh pull` command?
- How to detect which worktrees correspond to branches that are now merged into dev?
- How to safely kill tmux sessions (send exit command vs kill-session)?
- Should the branch also be deleted locally after cleanup?
- What about worktrees with uncommitted changes?

## Solution

Manual command, not a git hook. A post-merge hook only fires on `git merge`, not `git pull --rebase`, making it unreliable. A standalone `cleanup` command is predictable and safe.

**New script: `src/bin/cleanup`**
- Runs from the main repo (not a worktree) — uses `assert_not_worktree`
- Pulls dev from origin (`git pull origin dev`)
- Lists all koh worktrees by scanning `.koh-worktrees/*/`
- For each worktree, extracts the branch name and checks if it's merged into dev via `git branch --merged dev`
- If merged:
  1. Kill any matching tmux sessions (`koh-think-<id-slug>`, `koh-explode-<id-slug>`) using `tmux kill-session`
  2. Remove the worktree with `git worktree remove <path>`
- Prints what was cleaned up
- Skips worktrees with uncommitted changes (warn and continue)

**New slash command: `src/commands/cleanup.md`**
- Calls `.koh/bin/cleanup` from the main repo context

## Execution

1. Create `src/bin/cleanup` script following existing patterns (`set -euo pipefail`, source guards.sh, assert_not_worktree)
2. Create `src/commands/cleanup.md` slash command
3. Update `install.sh` to copy the new command
4. Test against current state: branches `1-puppet-system`, `3-fix-think-reread` are merged into dev and should be cleaned up

### Script structure

```
cleanup
├── assert_not_worktree
├── git pull origin dev
├── for each .koh-worktrees/*/ :
│   ├── get branch name from worktree
│   ├── skip if not merged into dev (git branch --merged dev)
│   ├── check for uncommitted changes — warn and skip if dirty
│   ├── tmux kill-session -t koh-think-<id-slug> (ignore if not exists)
│   ├── tmux kill-session -t koh-explode-<id-slug> (ignore if not exists)
│   └── git worktree remove <path>
└── summary of cleaned up worktrees
```

## Acceptance criteria
- `cleanup` command removes worktrees and tmux sessions for branches merged into dev
- Branches not merged into dev are left untouched
- Dirty worktrees (uncommitted changes) are skipped with a warning
- Local branches are kept (not deleted)
- No data loss — only acts on fully merged branches
