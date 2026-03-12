---
id: 8-multi-segment-sessions
branch: 8-multi-segment-sessions
worktree: /Users/francesco/projects/koh/.koh-worktrees/8-multi-segment-sessions
think-recording: ./think-recording.jsonl
explode-recording: ./explode-recording.jsonl
---

# 8-multi-segment-sessions: Build nusa — session persistence for Claude Code

## Problem

Koh's think/explode model enforces rigid phases. The real problem underneath is: AI session logs are ephemeral, machine-local, and invisible to reviewers. We need session persistence as a standalone tool that koh (and anything else) can build on.

## Solution

Build **nusa** — a hook-based tool that automatically snapshots Claude Code session logs into git repos via LFS and rehydrates them on any machine.

Full design: `nusa.md` in this repo (copy it into the new project as the design doc).

## Execution

Create a new project from scratch:

1. Create directory: `/Users/francesco/projects/nusa`
2. `git init`, create GitHub repo, set remote
3. Copy `nusa.md` from this repo into the new project root as the design doc
4. Build the PoC as described in the PoC section of `nusa.md`

### PoC deliverables

1. `hooks/session-start.sh` — Claude Code SessionStart hook
2. `hooks/post-commit.sh` — git post-commit hook
3. `hooks/post-checkout.sh` — git post-checkout/post-merge hook
4. `install.sh` — convenience installer
5. `README.md` — usage instructions

### Dependencies

`git`, `git-lfs`, `jq`

## Acceptance criteria

- `install.sh` sets up a target repo correctly (`.nusa/`, `.gitattributes`, `.gitignore`, `.claude/settings.local.json`, git hooks)
- SessionStart hook captures session ID into `.nusa/active-sessions`
- Post-commit hook copies session JSONL into `.nusa/sessions/` and creates a follow-up commit
- Post-checkout/post-merge hook hydrates sessions into `~/.claude/projects/`
- LFS tracking works (pointers in git, content on GitHub LFS)
- `install.sh` chains existing git hooks via `.pre-nusa` backup
- Empty branch checkout (no session files) exits cleanly
