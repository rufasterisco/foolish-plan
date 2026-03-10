> *"Put these foolish ambitions to rest."*
> — Margit, the Fell Omen

# foolish-plan

An organized way to record what happens in coding sessions with a coding agent. Currently supports Claude Code.

## Setup

Run the init script in any repo:

```sh
curl -fsSL https://raw.githubusercontent.com/rufasterisco/foolish-plan/master/init.sh | sh
```

This copies scripts and slash commands into `.claude/fool/` inside the repo, and:
- Verifies all requirements are in place (Claude Code, git, etc.)
- Installs custom slash commands into Claude Code

## How it works

Each coding session produces two artifacts that get committed alongside the code:

- **Issue file** (`./fool/issues/`) — describes the intent and plan for the session
  - Problem
  - Solution
  - Execution
  - Acceptance criteria
- **Recording file** (`./fool/recordings/`) — a log of the reasoning throughout the session, whether it's a human-AI conversation or the AI working autonomously. User and AI contributions are labeled separately, so code reviewers can see what the human asked about during the session

## Modes

### Dev container

Runs the coding session inside a [Claude Code dev container](https://code.claude.com/docs/en/devcontainer). Supports **YOLOS mode** (You Only Live Open Source) — the agent gets full autonomy ("classic yolo"), but the container is **jailed**:

- No external credentials are passed in
- No access to the local filesystem

This means there's no guarantee that code won't be exfiltrated (e.g. via prompt injection), which is a security trade-off you don't need to worry about in open source projects. What you *can* be sure of is that nothing leaks out of the container into your local environment.

The purpose of YOLOS is to be **uninterrupted** — the agent runs to completion without permission prompts.

YOLOS runs locally (not on remote systems). The container receives code via a **git worktree** — the repo's `.gitignore` takes care of filtering out secrets and only passing through the appropriate files.

**Credentials in the jail:** By default, none. External services (AWS, Stripe, GitHub, etc.) can optionally be passed in when needed. Important distinctions:

- AWS credentials are for API/frontend use only — not for CDK or infrastructure operations
- GitHub tokens only if `gh` CLI access is needed
- Credentials should be short-lived; managing them is the consumer's concern
- Infrastructure tools (CDK, `gh`, etc.) should not be run inside the container

**Docker inside the container:** Docker Compose files are available to the agent inside the dev container. A local Docker registry runs on the host — the container has **pull-only access** (no push). This lets the agent use host images without mounting the Docker socket, and prevents a compromised agent from pushing malicious images back to the registry.

### Local (planned)

Runs the session directly on your machine. Same security guarantees as your normal AI coding setup (whatever your permission settings are). Unlike YOLOS, you may need to approve permissions during the session.

> Local mode will only be implemented if the overhead of spinning up containers proves too heavy.

## tmux

Both modes run inside tmux, so you can attach to any session at any time. We provide a thin wrapper around tmux with only the essentials:

- `list` — show running sessions
- `connect` — attach to a session
- `disconnect` — detach from a session (needs investigation)

## Worktrees

Each session runs in its own git worktree. In container mode, the worktree is mounted into the container. Git commands (commit, push) can be issued both from inside the session and from outside.

Worktrees persist after the session ends. They can be cleaned up after the branch is merged/PR'd — since it's just a branch checkout, you can always check it out again from the main repo.

## Slash commands

Two main commands installed into Claude Code:

- `/think` — creates the issue file, opens a branch, collects and writes down the idea with an execution plan
- `/explode` — starts the coding session in a container (or locally), pipes all output to the recording file

## Recording

Two approaches under investigation:

1. **Pipe mode** — run Claude with `--output-format stream-json` and tee to a file
2. **Pull from `~/.claude/projects/`** — Claude Code already saves full JSONL conversation logs per session

Both preserve the full conversation (not a summary) with user/assistant labels. The best approach will be determined during development.

## Open questions

- `disconnect` command in tmux wrapper — needs investigation
- Local Docker registry — likely persistent across sessions, needs investigation
- Recording approach — pipe vs pull from Claude's session logs
