# /think implementation proposal

## What it is

A shell script + slash command. The user starts a conversation with claude, describes what they want to build, and together they flesh it out into a structured issue with an execution plan. The script handles the deterministic parts (ID, branch, worktree, recording, commit). Claude handles the thinking.

## Interface

```sh
# as a slash command inside claude:
/think add-auth

# claude then asks the user what they want to build, they discuss,
# and claude writes the issue file + runs the script to set everything up
```

## Output

A git branch `<id>-<slug>` with a worktree, containing one commit:

```
<worktree>/koh/issues/<id>-<slug>/
  issue.md              # structured plan (written by claude)
  think-recording.jsonl # session log (copied from ~/.claude/projects/)
```

## Architecture

The slash command (`.claude/commands/think.md`) is the orchestration layer. It tells claude to:
1. Ask the user what needs to be done
2. Build an execution plan together
3. Run the shell scripts to set up branch/worktree/issue dir
4. Write `issue.md` with the agreed plan
5. Run the shell scripts to extract the recording and commit

The shell scripts do the deterministic work. Claude is the glue.

## Scripts needed

### koh/bin/think-setup

Deterministic setup — run before the conversation:
1. Worktree guard (refuse if inside a worktree)
2. Generate next ID (from `koh/lib/id.sh`, scans branches)
3. Sanitize slug (lowercase, hyphens only)
4. Create branch + worktree at `.koh-worktrees/<id>-<slug>`
5. Create issue directory: `<worktree>/koh/issues/<id>-<slug>/`
6. Print the ID, slug, worktree path, and issue dir path (so claude knows where to write)

### koh/bin/think-finish

Deterministic cleanup — run after claude writes `issue.md`:
1. Extract recording (from `koh/lib/recording.sh`)
2. Commit issue.md + recording in the worktree
3. Print confirmation

## Slash command prompt

`.claude/commands/think.md` — lightweight:
- Run `koh/bin/think-setup <slug>` to set up branch and worktree
- Ask the user to explain what needs to be done
- Together, build an execution plan
- Write `issue.md` at the path provided by think-setup, with sections: Problem, Solution, Execution, Acceptance Criteria
- Run `koh/bin/think-finish <id-slug> <worktree-path>` to extract recording and commit

## Open questions

1. **Worktree location** — `.koh-worktrees/<id>-<slug>` inside the repo root. Added to `.gitignore`.
2. **Project dir encoding** — confirmed: `tr '/' '-'` on the absolute path.
3. **Session ID for recording** — since think is interactive, we can't get the session ID from `-p` output. Options: grab the newest `.jsonl` in the project dir, or find another way. Newest file should work since think-finish runs immediately after the session.
