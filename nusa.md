# nusa

**Session persistence for Claude Code.**

Automatically snapshots Claude Code session logs into your git repo via LFS and rehydrates them on any machine. Install once, forget about it.

## Why

The AI conversation is part of the work product. It captures what the human decided, what was rejected, what the agent did autonomously. Today it lives in `~/.claude/projects/` — ephemeral, unversioned, machine-local. nusa makes it a git-tracked artifact.

### Why LFS?

1. **Privacy.** Session logs contain full source code, prompts, reasoning. LFS lets you control where this data lives (see [Later](#later)).
2. **Git never forgets.** Deleting a file from git doesn't remove it from history. LFS content lives outside git — deletable independently.
3. **Accumulation.** Sessions are 100KB-500KB each. LFS stores pointers (~200 bytes) in git; actual content on the server.

PoC uses GitHub's built-in LFS (1GB free). Production: point `.lfsconfig` at your own server.

## How it works

Three hooks. No CLI, no manual steps after install.

### Hook 1: SessionStart (Claude Code hook)

Claude fires `SessionStart` on every new session. Configured in `.claude/settings.local.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".nusa/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

The hook receives JSON on stdin with `session_id`, `cwd`, `source` (startup/resume/clear/compact). It appends the session ID to `.nusa/active-sessions` (gitignored, local state). Append handles concurrent sessions.

`.nusa/hooks/session-start.sh`:
```bash
#!/bin/bash
session_id=$(jq -r '.session_id' < /dev/stdin)
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
echo "$session_id" >> "$repo_root/.nusa/active-sessions"
```

### Hook 2: pre-commit (git hook)

Copies each active session's JSONL from `~/.claude/projects/<encoded-cwd>/` into `.nusa/sessions/`, including subagent logs. Stages via `git add`. LFS handles the rest.

```bash
#!/bin/bash
repo_root=$(git rev-parse --show-toplevel)
active_file="$repo_root/.nusa/active-sessions"
[ -f "$active_file" ] || exit 0

sessions_dir="$repo_root/.nusa/sessions"
mkdir -p "$sessions_dir"

encoded=$(pwd | tr '/.' '--')
claude_dir="$HOME/.claude/projects/$encoded"

while IFS= read -r session_id; do
  [ -z "$session_id" ] && continue
  src="$claude_dir/$session_id.jsonl"
  [ -f "$src" ] || continue
  cp "$src" "$sessions_dir/$session_id.jsonl"
  [ -d "$claude_dir/$session_id" ] && cp -R "$claude_dir/$session_id" "$sessions_dir/"
done < "$active_file"

git add "$sessions_dir"
```

### Hook 3: post-checkout / post-merge (git hooks)

Hydrates session logs from `.nusa/sessions/` into Claude's local storage. After this, `claude --continue` or `--resume` picks them up.

```bash
#!/bin/bash
repo_root=$(git rev-parse --show-toplevel)
sessions_dir="$repo_root/.nusa/sessions"
[ -d "$sessions_dir" ] || exit 0

git lfs pull --include=".nusa/sessions/**"

encoded=$(pwd | tr '/.' '--')
claude_dir="$HOME/.claude/projects/$encoded"
mkdir -p "$claude_dir"

for src in "$sessions_dir"/*.jsonl; do
  [ -f "$src" ] || continue
  session_id=$(basename "$src" .jsonl)
  cp "$src" "$claude_dir/$session_id.jsonl"
  [ -d "$sessions_dir/$session_id" ] && cp -R "$sessions_dir/$session_id" "$claude_dir/"
done
```

### Install

nusa provides hook scripts and configuration. You integrate them into your project's git hook setup.

**What nusa ships:**
```
.nusa/
  hooks/
    session-start.sh      # Claude Code SessionStart hook
    pre-commit.sh         # git pre-commit: save sessions
    post-checkout.sh      # git post-checkout/post-merge: hydrate sessions
  sessions/               # where session JONLs are stored (LFS-tracked)
```

**What you configure:**

1. `.gitattributes` — LFS tracking:
   ```
   .nusa/sessions/**/*.jsonl filter=lfs diff=lfs merge=lfs -text
   ```

2. `.claude/settings.local.json` — SessionStart hook:
   ```json
   {
     "hooks": {
       "SessionStart": [
         {
           "matcher": "",
           "hooks": [{"type": "command", "command": ".nusa/hooks/session-start.sh"}]
         }
       ]
     }
   }
   ```

3. Git hooks — call nusa's scripts from your existing hook setup:
   - `pre-commit`: call `.nusa/hooks/pre-commit.sh`
   - `post-checkout`: call `.nusa/hooks/post-checkout.sh`
   - `post-merge`: call `.nusa/hooks/post-checkout.sh`

   How you wire this depends on your project. If you use **husky**, add the calls to `.husky/pre-commit`. If you use **lefthook**, add entries to `lefthook.yml`. If you use **raw git hooks**, call the scripts from `.git/hooks/`. nusa doesn't own your git hooks — it provides scripts, you call them.

4. `.gitignore` — add `.nusa/active-sessions` (local state, not committed)

5. `git lfs install` if not already done

**Convenience install script:**

For projects with no existing git hook setup, `install.sh` does all of the above, installing raw git hooks directly into `.git/hooks/`. If a hook already exists, it renames it to `<hook>.pre-nusa` and chains it.

```bash
./install.sh
# or
curl -fsSL https://raw.githubusercontent.com/<org>/nusa/main/install.sh | sh
```

After install: start Claude, work, commit, push. Sessions persist. Pull on another machine, sessions rehydrate.

## Not in scope

- No CLI after install — everything is hooks
- No workflow opinions (branching, issues, lifecycle) — that's koh's layer
- No session viewing — separate tool
- No LFS server management — bring your own
- No secret scanning — see [Later](#later)

## Reference

### Session storage

```
~/.claude/projects/<encoded-cwd>/<session-id>.jsonl
~/.claude/projects/<encoded-cwd>/<session-id>/subagents/agent-<id>.jsonl
```

Encoding: absolute path with `/` and `.` replaced by `-` (`/Users/me/foo` → `-Users-me-foo`).

Sessions are directory-scoped. `claude` = new session. `claude --continue` = most recent. `claude --resume` = picker.

### JSONL format

Each line is JSON. Key fields:

| What | How to identify |
|---|---|
| Human message | `type: "user"`, `userType: "external"`, `message.content` is string |
| Agent action | `type: "assistant"`, `message.content[].type: "tool_use"` |
| Code change | `tool_use.name` is `Edit` or `Write`, `file_path` in input |
| Command | `tool_use.name` is `Bash`, `command` in input |
| Branch | `gitBranch` field (present on every real message) |

### Rehydration caveat

JSONL messages contain `cwd` with the original machine's absolute path. Needs PoC testing: does `claude --continue` work when `cwd` doesn't match? If not, the hydration hook must rewrite `cwd` fields.

### Branch lifecycle

Session files live on feature branches. On merge:
1. LFS pointers merge into main (~200 bytes each)
2. Remove from main: `git rm .nusa/sessions/ && git commit`
3. Delete branch if desired

Sessions remain recoverable via `git log --all -- .nusa/sessions/` → `git show <commit>:<path>` → `git lfs pull`.

True deletion: delete the LFS object from the server. Pointer becomes dead. No history rewriting.

## PoC

Proves the automated loop: session starts → hook captures ID → commits include session logs → checkout rehydrates.

**Deliverables:** `install.sh`, SessionStart hook, pre-commit hook, post-checkout/post-merge hooks. GitHub's built-in LFS.

**Dependencies:** `git`, `git-lfs`, `jq`

**Validate:**
- SessionStart hook captures session ID reliably
- pre-commit copies correct JSONL and stages it
- LFS tracking works (pointers in git, content on GitHub)
- Rehydration restores sessions, `claude --continue` works
- Multiple concurrent sessions (append behavior)
- Cross-machine rehydration (cwd mismatch)

**Not in PoC:** external LFS server, secret scrubbing, session viewer, post-merge cleanup automation, non-Claude tools.

## Later

### External LFS server

Control where session data lives. Add `.lfsconfig`:
```ini
[lfs]
    url = https://your-lfs-server.example.com/org/repo
```
Git traffic goes to GitHub; LFS blobs go to your server. Options: **rudolfs** (Rust) + S3, **giftless** (Python) + S3/Azure/GCS, **MinIO** (self-hosted). Cost: ~$0.023/GB/month. Enables true deletion: remove S3 object, pointer dies, no history rewriting.

### Secret scrubbing

Post-hoc, not at save time. Run gitleaks on JSONL, replace secrets with `[REDACTED]`, upload scrubbed version (new LFS object), delete old object from server. Sensitive content truly gone.

### Session viewer

Separate tool. Render session logs for code review: human messages only, file changes by type, timeline of collaboration vs autonomous execution.

### Post-merge cleanup

Auto-remove session files from main after merge. Git hook or CI step.

### Non-Claude tools

Cursor, Aider, Copilot have different session formats. Plugin/adapter system needed. Significant effort.

## Landscape

| Tool | Approach | vs nusa |
|---|---|---|
| **Claudit** | Git notes on commits | No rehydration, no LFS |
| **git-memento** | Git notes | Same |
| **claude-code-sync** | JSONL sync to git repo, LFS support | No rehydration, no hooks |
| **Entire CLI** | Shadow branches for checkpoints | No rehydration |
| **Git-AI** | Line-level attribution | Attribution, not persistence |
| **ContextLedger** | Metadata capsules | Metadata only |
| **SpecStory CLI** | Sessions → markdown | Lossy, no rehydration |

**nusa's edge:** fully automated (hooks only), rehydration (resume anywhere), privacy via external LFS (post-PoC), true deletion (post-PoC).
