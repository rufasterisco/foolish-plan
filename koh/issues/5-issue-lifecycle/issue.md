---
id: 5-issue-lifecycle
branch: 5-issue-lifecycle
worktree: /Users/francesco/projects/koh/.koh-worktrees/5-issue-lifecycle
think-recording: ./think-recording.jsonl
explode-recording: ./explode-recording.jsonl
---

# 5-issue-lifecycle: Issue state management and lifecycle tracking

## Problem
Koh issues go through a lifecycle but there's no way to track or query their state. Need to distinguish:

1. **thinking** — issue is being planned (think session active)
2. **executing** — issue is being coded (explode session active)
3. **done** — execution completed, ready for review/merge
4. **merged** — branch merged into dev, worktree can be cleaned up

Currently there's no state tracking at all. This blocks building features like:
- `koh status` to see what's in flight
- Auto-cleanup of merged worktrees (issue #4)
- Knowing which issues need attention

## Design considerations from user

**Requirements:**
- State must be queryable fast — no parsing frontmatter or reading file contents
- Filesystem-based so `ls` is enough to see state

**Ideas discussed:**
- **Status files** — touch/rm a file like `.thinking`, `.executing`, `.done`, `.merged` in the issue directory. `ls` the issue folder and you know the state.
- **Subdirectories** — move issue folders between `koh/issues/thinking/`, `koh/issues/executing/`, `koh/issues/done/`, `koh/issues/merged/`. State is the parent directory.
- **Frontmatter** — rejected as too slow (requires reading and parsing the file)

**Trade-offs to discuss:**
- Status files: simple, but issue stays in one place (good for git, paths don't change)
- Subdirectories: clean `ls` per state, but moving files means paths change (breaks worktree references, frontmatter paths, etc.)
- Status files are probably better since issue paths are referenced in frontmatter and by scripts

## Solution

Use **status files** in each issue directory. Touch/rm a dotfile (`.thinking`, `.executing`, `.done`, `.merged`) to represent the current state.

```
koh/issues/5-issue-lifecycle/
├── issue.md
├── .thinking              ← current lifecycle state
├── think-recording.jsonl
└── explode-recording.jsonl
```

**Why this approach:**
- Issue paths never change — worktree refs, frontmatter, and scripts stay stable
- `ls -a` on any issue dir shows state instantly
- Trivial to implement: `touch .thinking`, `rm .thinking && touch .executing`
- Each transition point already has a script that can own the state change

**State transitions and owners:**
1. `think-setup` → `touch .thinking`
2. `explode` (start) → `rm .thinking && touch .executing`
3. `explode` (finish) → `rm .executing && touch .done`
4. post-merge cleanup → `rm .done && touch .merged`

**Querying state:** A `koh status` helper can iterate issue dirs and check which dotfile exists. One-liner: `for d in koh/issues/*/; do [ -f "$d/.thinking" ] && echo "$d"; done`

## Execution

1. **Add a state helper library** — `src/lib/state.sh`
   - `set_state <issue-dir> <state>`: remove any existing state file, touch the new one
   - `get_state <issue-dir>`: check which dotfile exists, return the state name (or `unknown`)
   - Validates state is one of: `thinking`, `executing`, `done`, `merged`

2. **Wire into existing scripts:**
   - `src/bin/think-setup`: call `set_state "$issue_dir" thinking` after creating the issue dir
   - `src/bin/explode`: call `set_state "$issue_dir" executing` at session start, `set_state "$issue_dir" done` after session finishes
   - Merge/cleanup script (future, issue #4): call `set_state "$issue_dir" merged`

3. **Backfill existing issues** — optional: add a one-time script or document how to manually set state for issues created before this change

4. **Git tracking** — state files should be committed (they're part of the issue's lifecycle record)

## Acceptance criteria
- Each koh issue has a trackable lifecycle state
- State is queryable from the filesystem without parsing files
- Scripts can transition state (think-setup → thinking, explode → executing, etc.)
- Foundation for `koh status` and auto-cleanup features
