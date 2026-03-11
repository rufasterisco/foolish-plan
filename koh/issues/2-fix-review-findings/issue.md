---
id: 2-fix-review-findings
branch: 2-fix-review-findings
worktree: /Users/francesco/projects/koh/.koh-worktrees/2-fix-review-findings
think-recording: ./think-recording.jsonl
explode-recording: ./explode-recording.jsonl
---

# 2-fix-review-findings: Fix security and code quality issues from review

## Problem
A code review surfaced multiple security and code quality issues across koh's codebase. The findings range from high-severity (bypassable gitleaks scrubbing) to low-severity (temp file cleanup, missing functions). Key areas:

**Security (High/Medium):**
- Gitleaks scrubbing is bypassable — custom API keys, passwords in connection strings, or JSON-escaped secrets can slip through and get auto-committed
- VS Code extension shell injection — unvalidated tmux session names allow command injection
- Write + execute chain — Claude can modify `.koh/bin/` scripts then run them in worktrees (prompt injection vector)
- `think-launch` variable quoting — interpolates vars directly into tmux command string instead of using `printf '%q'`
- Recordings auto-committed without user confirmation
- VS Code auto-attach without consent for any `koh-*` tmux session

**Code Quality (Important):**
- `extract_latest_recording` is called by `think-finish` but doesn't exist in recording.sh
- Race condition in ID generation — concurrent `/think` calls can get the same ID (TOCTOU)
- `think-finish` is never called — no slash command or automation invokes it
- `ls` output parsed programmatically in recording.sh — fragile with special chars

**Code Quality (Minor):**
- Duplicated guard functions, boilerplate, and patterns
- `explode.md` docs say `koh-4-add-auth` but actual name is `koh-explode-4-add-auth`
- Extension uses blocking `execSync` on 2-second poll
- `vscode-extension/out/` committed despite gitignore
- Missing `-r` flag on `read` in explode wrapper
- Inconsistent error handling (`|| true` in explode but not think-finish)
- Hardcoded file list in install.sh
- No version tracking, no tests

## Solution

Fix all findings except: race condition in ID generation (rare, not worth the complexity) and tests/version tracking (out of scope). Defer write+execute chain fix (koh still under active development — track as future TODO).

### Security fixes

1. **Gitleaks scrubbing hardening** — Two layers:
   - Enable `--max-decode-depth` in gitleaks invocation to catch encoded/escaped secrets
   - Add user confirmation prompt before auto-committing recordings in `explode` (so humans review what gets committed)

2. **VS Code extension shell injection** — Validate tmux session names against `^koh-(think|explode)-[0-9]+-[a-z0-9-]+$` before interpolating into shell commands.

3. **`think-launch` variable quoting** — Replace `sed` interpolation of `$issue_dir` into the prompt template with `printf '%q'` or a safer substitution that handles special chars.

4. **VS Code auto-attach consent** — Add a confirmation prompt (VS Code `showInformationMessage`) before auto-attaching to a tmux session. User must approve.

### Code quality fixes

5. **Remove `think-finish`** — Delete `.koh/bin/think-finish` and remove any references to it. It's never called, and `extract_latest_recording` (which it depends on) doesn't exist.

6. **Fix `ls` parsing in recording.sh** — Replace `ls "$dir"/*.jsonl | sort` with glob arrays or `find -print0` + `while read -r -d ''` to handle filenames with special chars.

7. **Fix duplicated guard functions** — `src/lib/guards.sh` and `.koh/lib/guards.sh` are identical copies. `install.sh` copies `src/` → `.koh/`, so only `src/` needs editing. Remove duplication in any shared boilerplate.

8. **Fix `explode.md` session name** — Change `koh-4-add-auth` to `koh-explode-4-add-auth` in the docs.

9. **Replace blocking `execSync` in extension** — Use async `child_process.exec` or `cp.execFile` with promises instead of `execSync` on the 2-second poll.

10. **Remove committed `vscode-extension/out/`** — `git rm -r vscode-extension/out/` (already in `.gitignore`).

11. **Add `-r` flag to `read`** in explode wrapper (line 111).

12. **Remove inconsistent error handling** — Since `think-finish` is being deleted, this is resolved. Review remaining scripts for consistency.

13. **Replace hardcoded file list in install.sh** — Use a glob or directory walk of `src/` instead of listing individual files.

### Future TODO (not this PR)

- **Write+execute chain** — Remove write permission on `.koh/bin/` from `settings.local.json` once koh development stabilizes.

## Execution

### Step 1: Security — recording.sh and explode
- In `recording.sh`: add `--max-decode-depth` flag to gitleaks invocation
- In `explode`: add user confirmation prompt before `git add`/`git commit` of recordings
- Fix `ls` parsing in recording.sh (glob arrays)
- Fix temp file cleanup paths

### Step 2: Security — VS Code extension
- Add session name validation regex in `extension.ts`
- Add auto-attach consent prompt via `showInformationMessage`
- Replace `execSync` with async alternative

### Step 3: Security — think-launch
- Replace `sed` variable interpolation with safe quoting

### Step 4: Code quality cleanup
- Delete `think-finish`
- Fix `explode.md` session name in docs
- `git rm -r vscode-extension/out/`
- Add `-r` to `read` in explode
- Replace hardcoded file list in install.sh with glob

### Step 5: Final review
- Grep for any remaining references to `think-finish` or `extract_latest_recording`
- Verify all scripts still work end-to-end

## Acceptance criteria

- [ ] `gitleaks` invoked with `--max-decode-depth` in recording.sh
- [ ] `explode` prompts user before committing recordings
- [ ] VS Code extension validates session names before shell interpolation
- [ ] VS Code extension asks for consent before auto-attaching
- [ ] VS Code extension uses async exec instead of `execSync`
- [ ] `think-launch` uses safe variable quoting (no raw `sed` interpolation)
- [ ] `think-finish` deleted, no dangling references
- [ ] `ls` parsing replaced with safe alternative in recording.sh
- [ ] `explode.md` shows correct session name format
- [ ] `vscode-extension/out/` removed from git
- [ ] `read -r` in explode wrapper
- [ ] install.sh uses glob instead of hardcoded file list
- [ ] All existing scripts still function correctly after changes
