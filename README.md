> *"Put these foolish ambitions to rest."*
> — Margit, the Fell Omen

# koh

© 2026 [rufasterisco](https://github.com/rufasterisco). All rights reserved. See [LICENSE](LICENSE).

An organized way to run coding sessions with a coding agent. Currently supports Claude Code.

Session recording is handled by [nusa](https://github.com/rufasterisco/nusa).

## Setup

Requirements: `git`, `claude`, `tmux`, `jq`

Run the install script in any repo:

```sh
/path/to/koh/install.sh
```

Or via curl:

```sh
curl -fsSL https://raw.githubusercontent.com/rufasterisco/koh/master/install.sh | sh
```

This installs scripts to `.koh/`, slash commands to `.claude/commands/koh/`, and creates `koh/issues/` for issue files. Optionally installs the VS Code extension for tmux session management.

Reinstalling updates tooling without touching issues, worktrees, or branches.

## Flow

### 1. Think

From your main claude session, run `/think`. Describe what you want to build.

What happens:
1. Claude generates a slug from the conversation (e.g. `add-auth`)
2. `think-setup` creates a git branch, worktree, and issue template (`koh/issues/<id-slug>/issue.md`)
3. Claude fills in the template with everything discussed so far — problem, solution, execution plan
4. `think-launch` opens a tmux session with a fresh claude in the worktree
5. The VS Code extension auto-attaches to the session

You continue planning with the inner claude until all sections of the issue template are complete.

### 2. Explode

From inside the worktree (the think session or a new terminal), run `/explode`.

What happens:
1. Validates you're in a koh worktree
2. Opens a tmux session with a fresh claude. The issue template is there — claude reads it and executes the plan

### 3. Result

Each issue directory contains:

```
koh/issues/<id-slug>/
  issue.md                  # plan (filled during think)
```

The issue plan is committed to the branch alongside the code changes.

## Architecture

### Worktrees

Each session runs in its own git worktree at `.koh-worktrees/<id-slug>/`. Worktrees are gitignored. Guards enforce context: think runs from the main repo, explode runs from inside a worktree.

Worktrees persist after the session ends. They can be cleaned up after the branch is merged/PR'd — since it's just a branch checkout, you can always check it out again from the main repo.

### Session recording

Session recording is handled by [nusa](https://github.com/rufasterisco/nusa). nusa captures Claude Code session logs automatically via git hooks — koh doesn't need to manage recordings.

### tmux

Both think and explode sessions run inside tmux. Attach with the VS Code extension (Cmd+Shift+P → "koh: Attach to session") or `tmux attach -t koh-<id-slug>`. Detach with `ctrl+b d` — the session keeps running.

### ID generation

Issue IDs are sequential, derived from existing git branch names matching `<number>-<slug>`. The ID module is encapsulated — other scripts call `next_id`, never generate IDs themselves. The strategy can be swapped later (date-based, UUID, GitHub issue number) without changing the rest of the system.

### Slash commands

- `/think` — plan a new issue (creates worktree, fills template, launches think session)
- `/explode` — start coding (launches explode session)

### VS Code extension

Optional. One command: "koh: Attach to session" — lists koh tmux sessions in a quick pick. Also auto-attaches when new sessions appear.

## Later

### Dev container / YOLOS

Runs the coding session inside a jailed container. YOLOS (You Only Live Open Source) gives the agent full autonomy without permission prompts, but the container is locked down:

- No external credentials passed in
- No access to the local filesystem
- No git push credentials (no SSH keys, no tokens, no `GIT_ASKPASS`)

The container receives code via a git worktree mounted read-write. The host picks up commits after the session ends — the agent never pushes directly.

**Credentials in the jail:** By default, none. External services (AWS, Stripe, GitHub, etc.) can optionally be passed in when needed:

- AWS credentials for API/frontend use only — not for CDK or infrastructure operations
- GitHub tokens only if `gh` CLI access is needed
- Credentials should be short-lived; managing them is the consumer's concern
- Infrastructure tools (CDK, `gh`, etc.) should not be run inside the container

**Docker inside the container:** Docker Compose files are available to the agent. A local Docker registry runs on the host — the container has pull-only access (no push). This lets the agent use host images without mounting the Docker socket, and prevents a compromised agent from pushing malicious images back to the registry.

Code exfiltration via network is an accepted trade-off in YOLOS — the assumption is open source projects where code isn't secret.

### Branch isolation (container mode)

Git worktrees provide branch isolation by design. If you have worktrees A and B:

- The container for session B only has worktree B mounted — no filesystem access to worktree A's directory
- `git checkout A` fails inside B's container because git knows branch A is checked out in another worktree
- The agent cannot commit to branch A without checking it out
- Without push credentials, the agent can't push anything to remote

The agent **can** read other branches' content via git commands (`git show A:file`), since the object store is shared. This is acceptable — the concern is preventing writes, not reads.

### Security model (container mode)

| Threat | Mitigation |
|---|---|
| Push malicious code to remote | No git push credentials in container |
| Inject code into another worktree | Worktree mount isolation — only the session's worktree is mounted |
| Checkout another branch | Git refuses — branch already checked out in another worktree |
| Push malicious Docker image | Local registry is pull-only from container |
| Access host filesystem | Only the worktree is mounted, nothing else |
| Leak secrets via commit | `.gitignore` filters the worktree; no credentials mounted by default |
| Exfiltrate code via network | Accepted trade-off in YOLOS (open source assumption) |

What the agent **can** do:
- Read other branches' content via `git show` (shared object store)
- Commit freely to its own branch
- Pull images from the local registry
- Make outbound network requests

### Other planned features

- Think resume / think discard
- Credential proxy for containers
- VS Code extension enhancements

## Security

### Input validation

Branch names and slugs are validated against `^[0-9]+-[a-z0-9-]+$`. Scripts use quoted heredocs and environment variables to prevent shell injection.

### Worktree isolation

Guards prevent running think inside a worktree or explode from the main repo. This prevents nested worktrees and ensures scripts run in the correct context.
