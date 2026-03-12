---
id: 8-multi-segment-sessions
branch: 8-multi-segment-sessions
worktree: /Users/francesco/projects/koh/.koh-worktrees/8-multi-segment-sessions
think-recording: ./think-recording.jsonl
explode-recording: ./explode-recording.jsonl
---

# 8-multi-segment-sessions: Support multiple think/explode segments per issue

## Problem

Koh currently enforces a rigid two-phase model: one think, one explode. Real work isn't linear — you think, code a bit, realize something, think again, code more. Use cases not covered:

- Coding collaboratively with AI (not fully autonomous)
- PR reviews (collaborative reasoning, not planning)
- Multi-step tasks: "code this, then do that" — multiple rounds of thinking and executing
- Revisiting decisions mid-implementation

The core objective remains: **keep reasoning committed alongside code**. The conversation between user and claude (collaborative) should be kept separate from autonomous execution. But the boundary between "autonomous agent" and "human + agent" shifts back and forth within a single issue.

## Discussion so far

### The core insight
What matters isn't think vs code — it's **who's driving**:
- **Collaborative**: human and claude going back and forth, making decisions together
- **Autonomous**: claude executing alone, human steps away

Both are valuable to record but for different reasons. Collaborative segments capture decisions and reasoning. Autonomous segments capture what the agent actually did when left alone.

### Ideas explored

**1. Sessions as a stream of numbered segments**
Instead of one think + one explode, an issue becomes a sequence:
```
koh/issues/8-foo/
  issue.md
  segments/
    01-think.jsonl
    02-explode.jsonl
    03-think.jsonl
    04-explode.jsonl
```
Each `/think` or `/explode` appends the next segment.

**2. Fluid boundary with `/yolo` and `/back`**
Instead of separate sessions, one continuous session with mode markers:
- `/yolo` — "I'm stepping away, do the thing autonomously"
- `/back` — "I'm here again, let's collaborate"
Segments are markers in the recording for reviewers.

**3. Think as any collaborative reasoning**
Think isn't just "planning" — it's any collaborative session (plan, review, debug, design). Explode isn't just "build" — it's any autonomous execution. The taxonomy is collaborative vs autonomous, not plan vs code.

**4. Minimal change: allow multiple**
Let `/think` and `/explode` be called multiple times per issue. Number the recordings. Don't change the mental model, just remove the "once each" constraint. Gets 80% of the value.

### Assessment
Option 4 is the pragmatic next step — backwards compatible, solves immediate pain. Option 2 is the long-term direction — making the human/autonomous boundary fluid rather than a rigid phase gate.

### Primitives analysis

Claude Code's JSONL session logs already contain everything we need:
- **`type: user, userType: external`** — human messages (verbatim)
- **`type: assistant`** — Claude's responses and reasoning
- **Tool calls** with full inputs: `Edit`/`Write` (code changes), `Read`/`Grep`/`Glob` (exploration), `Bash` (commands)
- **File paths** in tool calls distinguish code vs docs vs config changes
- **Timestamps, session IDs, git branch** metadata

No new markers or annotations needed — the signal for "where did the human reason?" vs "what did the agent do autonomously?" is already in the data.

### Session log as the primary artifact

Key realization: the JSONL session log should be the **primary artifact**, not a derivative. The issue.md becomes a quick-scan summary.

**The flow:**
1. **Start** — koh starts a Claude Code session scoped to an issue/branch
2. **Snapshot on commit** — a git hook (or explicit `/cut` command) copies the session JSONL from `~/.claude/projects/` into the issue directory in the repo
3. **Overwrite is fine** — always the latest full conversation, not incremental diffs
4. **Resume anywhere** — same machine: `/resume`. Different machine: pull the branch, rebuild `sessions-index.json` from the committed JSONL, resume the conversation
5. **Explode remotely** — a remote machine rehydrates the session. The AI has the full conversation context to execute autonomously — no separate "handoff" needed
6. **Review** — the JSONL is committed alongside the code. Reviewer can see the full human+AI conversation, filter by human input, see what files were touched

**Implications:**
- Think/explode merge into one continuous flow — no rigid phases
- Context transfer between think and explode is solved (same session)
- The collaborative vs autonomous boundary is visible in the data (human messages vs tool-only sequences) without needing explicit mode switches
- issue.md is a summary artifact for quick scanning, not the source of truth

### Session scoping

One koh session = one Claude Code session = one issue. The session boundary IS the feature boundary. This is already how worktrees work — each issue gets its own worktree, its own session.

Risk: if someone works on unrelated things in the same session, the log gets polluted. Mitigation: koh starts the session scoped to an issue; snapshotting at commit time captures the relevant slice.

### Storage: Git LFS with external server

Session JSONL files should NOT live in git history or on GitHub's servers:
- **Privacy**: session logs contain full file contents, prompts, reasoning, potentially sensitive code. You need to control where this data lives.
- **Git never forgets**: even if you `rm` a JSONL and commit, every old version stays in git history forever. Repo bloat is inevitable.
- **Size**: current sessions are 100KB-500KB each. Manageable now, but accumulates across issues and over time.

**Solution: Git LFS backed by a self-hosted/private server.**

How it works:
- `.gitattributes` tracks `*.jsonl` via LFS
- `.lfsconfig` points to your own server (not GitHub's LFS)
- Git stores a ~200 byte pointer file in the repo; actual JSONL lives on your server
- `git push`/`git pull` still go to GitHub for code; only LFS blobs go to your server

Server options (lightest first):
- **rudolfs** (Rust binary) + S3 bucket — handles only metadata, issues presigned URLs for direct S3 transfer
- **giftless** (Python) + S3/Azure/GCS
- **MinIO** for fully self-hosted S3-compatible storage

Cost: S3 storage ~$0.023/GB/month. Negligible for session logs.

Benefits:
- **You control where conversation data lives** — the primary reason
- Repo stays lean (only pointer files in git history)
- Can set S3 lifecycle rules to archive/delete old sessions independently of git
- Can delete LFS objects without rewriting git history

Trade-offs:
- Contributors need credentials for the LFS server
- GitHub web UI shows pointer files, not content
- CI needs explicit LFS credentials
- Extra infrastructure to maintain (though rudolfs + S3 is minimal)

### Open concerns

- **sessions-index.json**: rehydration depends on rebuilding this undocumented index. It's an implementation detail that could break.
- **Backwards compatibility**: existing think/explode workflow should still work. New continuous flow is additive.

### What others are doing

No mainstream tool captures full decision provenance (human reasoning + AI execution trail). Closest:
- **Git-AI**: per-edit checkpoint diffs tagged AI vs human, attached via Git Notes
- **ContextLedger**: session metadata "capsules" (prompts, tool calls, files touched)
- **Cursor Blame / AgentBlame**: line-level AI vs human attribution in diffs
- **Propel's schema**: proposed PR artifact with intent, execution trail, human overrides (not shipped)

All focus on the diff or metadata — none capture the full conversation. Koh's approach of committing the session log is more complete.

## Solution
TBD — needs further discussion.

## Execution
TBD.

## Acceptance criteria
TBD.
