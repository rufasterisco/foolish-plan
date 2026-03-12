---
id: 9-nusa-integration
branch: 9-nusa-integration
worktree: /Users/francesco/projects/koh/.koh-worktrees/9-nusa-integration
---

# 9-nusa-integration: Replace manual log copying with nusa

## Problem

Koh currently copies Claude Code session logs manually — snapshotting `~/.claude/projects/`, diffing before/after, scrubbing secrets via gitleaks, and committing the result as `think-recording.jsonl` / `explode-recording.jsonl`. This is fragile and tightly coupled to Claude Code's internal file layout.

## Context

- [nusa](https://github.com/rufasterisco/nusa) is a hook-based system that automatically captures Claude Code session logs into `.nusa/sessions/` via Git LFS on every commit, and rehydrates them on checkout/merge. No CLI needed — just git hooks.
- nusa fully replaces koh's manual extraction, scrubbing (gitleaks), and recording commit pipeline. Koh just needs to commit; nusa's post-commit hook handles the rest.
- nusa installation is out of scope — will be handled in a future task.
- Related to issue #8 (multi-segment-sessions).

## Solution

Remove all recording-related code from koh. nusa handles session persistence transparently via git hooks — koh doesn't need to know about it. Any mention of recordings should be removed, replaced by a brief note that we use nusa for session recording.

## Execution

### 1. Delete `src/lib/recording.sh`
The entire file is no longer needed: `encode_project_dir`, `session_log_dir`, `scrub_recording`, `snapshot_recordings`, `extract_all_recordings`, `extract_new_recordings`, `extract_latest_recording`.

### 2. Gut recording logic from `src/bin/explode`
Remove:
- The "extract think recording" step (calls `extract_all_recordings`)
- The `snapshot_recordings` call
- The post-exit `extract_new_recordings` call and its commit prompt
- The `source` of `recording.sh`

Keep: tmux session launch, lifecycle state transitions, validation, the actual Claude invocation.

### 3. Gut recording logic from `.koh/bin/think-finish`
Remove the `extract_latest_recording` call and the recording commit. Keep any non-recording logic (if any).

### 4. Update `src/templates/issue.md`
Remove the `think-recording` and `explode-recording` frontmatter fields.

### 5. Update `install.sh`
- Remove `gitleaks` from required dependencies check.
- Add a TODO/note: "Session recording is handled by nusa (https://github.com/rufasterisco/nusa). nusa installation will be integrated in a future task."

### 6. Remove existing recording artifacts
Delete all `think-recording.jsonl` and `explode-recording.jsonl` files from `koh/issues/*/`.

### 7. Update docs
- In any docs that reference the recording pipeline (`docs/recording-extraction/`, `docs/investigations/recording-approach.md`, etc.), either remove or replace with a note pointing to nusa.
- Update `README.md` if it describes the recording pipeline.

## Acceptance criteria

- `recording.sh` is gone.
- No code anywhere calls `extract_*_recordings`, `snapshot_recordings`, `scrub_recording`, or references gitleaks.
- `explode` and `think-finish` still work (launch sessions, manage lifecycle) but do zero recording work.
- Issue template has no recording frontmatter.
- `install.sh` does not require gitleaks.
- All `*-recording.jsonl` files removed from `koh/issues/`.
- A brief note exists (in install.sh or README) that session recording is handled by nusa.
- `grep -r recording src/` returns nothing except the nusa reference note.
