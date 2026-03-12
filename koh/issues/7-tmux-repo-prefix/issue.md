---
id: 7-tmux-repo-prefix
branch: 7-tmux-repo-prefix
worktree: /Users/francesco/projects/koh/.koh-worktrees/7-tmux-repo-prefix
think-recording: ./think-recording.jsonl
explode-recording: ./explode-recording.jsonl
---

# 7-tmux-repo-prefix: Add repo name prefix to tmux session names

## Problem
When using koh across multiple repos, all tmux sessions are named `koh-<id-slug>` — e.g. `koh-3-fix-login`. If you have sessions from different repos, they all look the same in `tmux ls` and there's no way to tell which repo a session belongs to.

## Solution
Prefix tmux session names with the repo directory name. New pattern: `koh-<repo>-<type>-<id-slug>`.

Example: `koh-myapp-think-3-fix-login` vs `koh-backend-explode-5-add-auth`.

Repo name derived via `basename` of the git toplevel directory — simple, no parsing, works everywhere.

## Execution

1. **Add a `repo_prefix` helper** in `src/lib/id.sh` (or a new `src/lib/repo.sh`):
   - `repo_prefix=$(basename "$(git rev-parse --show-toplevel)")`
   - Sanitize to lowercase alphanumeric + hyphens to be tmux-safe

2. **Update `src/bin/think-launch`** (line ~40):
   - Change `session_name="koh-think-$id_slug"` → `session_name="koh-${repo_prefix}-think-$id_slug"`

3. **Update `src/bin/explode`** (line ~68):
   - Change `session_name="koh-explode-$id_slug"` → `session_name="koh-${repo_prefix}-explode-$id_slug"`

4. **Update `src/bin/cleanup`** (lines ~68-69):
   - Change kill targets to use `koh-${repo_prefix}-think-$branch` and `koh-${repo_prefix}-explode-$branch`

5. **Update `vscode-extension/src/extension.ts`** (line ~7):
   - Change `SESSION_NAME_RE` from `/^koh-(think|explode)-[0-9]+-[a-z0-9-]+$/` to `/^koh-[a-z0-9-]+-(think|explode)-[0-9]+-[a-z0-9-]+$/`

6. **Update docs** (`src/commands/think.md`, `src/commands/explode.md`):
   - Update session name examples to reflect new pattern

## Acceptance criteria
- tmux sessions from different repos are visually distinguishable
- Existing commands (cleanup, attach) still work with the new naming
- VS Code extension still detects and attaches to sessions
