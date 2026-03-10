# /think implementation proposal

## What it is

A shell script the user runs from the host. It takes a slug and a rough idea, launches a Claude session to flesh it out into a structured issue, saves both the issue file and the session recording, creates a branch + worktree, and commits everything.

## Interface

```sh
koh/bin/think <slug> "<idea>"

# example:
koh/bin/think add-auth "Add JWT authentication to the API endpoints. Use RS256 keys."
```

## Output

A git branch `<id>-<slug>` with a worktree, containing one commit:

```
<worktree>/koh/issues/<id>-<slug>/
  issue.md              # structured plan (written by claude)
  think-recording.jsonl # session log (copied from ~/.claude/projects/)
```

## Steps

### Step 0: worktree guard

- Refuse to run inside a worktree. All koh commands must run from the main repo checkout.
- Detection: `git rev-parse --git-common-dir` differs from `git rev-parse --git-dir` → you're in a worktree.
- This is a shared guard (same check in every koh script). Lives in `koh/lib/guards.sh`.

### Step 1: next-id

- Read existing `koh/issues/` folders, find highest number, add 1
- If no folders exist, start at 1
- Separate function (README says ID generation is its own module)
- Input: path to `koh/issues/`
- Output: a number (e.g. `4`)

### Step 2: slug

- User provides it as the first argument: `koh think add-auth "..."`
- Sanitize: lowercase, hyphens only, no special chars
- No API call needed

### Step 3: branch + worktree

- Branch name: `<id>-<slug>` (e.g. `4-add-auth`)
- Create worktree: `git worktree add <worktree-location> -b <id>-<slug>`
- `/think` works inside the worktree — writes `issue.md` there, commits there
- This way the issue file lives on the feature branch from the start
- The worktree is ready for `/explode` to use later

### Step 4: issue directory

- `mkdir -p <worktree>/koh/issues/<id>-<slug>/`

### Step 5: claude session

- Run from inside the worktree directory (so claude sees the right project context)
- `claude -p "<prompt>" --output-format stream-json --verbose | tee <tmp-file>`
- Uses `-p` (non-interactive, one-shot). The user provides the idea upfront, claude structures it.
- The prompt tells claude to write `koh/issues/<id>-<slug>/issue.md` with sections:
  - Problem
  - Solution
  - Execution
  - Acceptance Criteria

### Step 6: session ID

- Parse from the stream-json output: `jq -r '.session_id // empty' <tmp-file> | head -1`
- The first line (type `system`) contains the session ID

### Step 7: recording

- Session log path: `~/.claude/projects/<project-dir-encoded>/<session-id>.jsonl`
- Project dir encoding: absolute worktree path with `/` replaced by `-`, leading `-`
- Copy to `<worktree>/koh/issues/<id>-<slug>/think-recording.jsonl`

### Step 8: commit

- `git add koh/issues/<id>-<slug>/issue.md koh/issues/<id>-<slug>/think-recording.jsonl`
- `git commit -m "<id>-<slug>: plan issue"`

## Open questions

1. **Worktree location** — `../koh-worktrees/<id>-<slug>` relative to the repo? Needs a convention.
2. **Project dir encoding** — need to verify exactly how claude encodes the worktree path into the `~/.claude/projects/` directory name. We saw `-Users-francesco-deleteme-koh-recording-test` — is it always just slashes replaced by hyphens?
3. **Claude prompt** — needs to be crafted carefully. Should we give it a template file?
4. **Error handling** — what if claude fails, what if the branch already exists, etc.
