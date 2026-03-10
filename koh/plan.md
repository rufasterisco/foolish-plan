# koh — project plan

## Core blocks (build order)

1. **ID generation** — module that generates issue IDs. Sequential for now, swappable later. Everything else calls it.
2. **Recording extraction** — logging wrapper. Finds `~/.claude/projects/`, maps session IDs to files, copies JSONL to the issue folder. Shared by /think and /explode.
3. **/think** — plans an issue. Runs on the host, uses claude to write a structured issue file, captures the session recording, creates branch + worktree.
4. **/explode (local)** — runs the coding session on the host. Launches claude interactively, pointed at an existing issue/branch from /think. Captures the session recording when done.
5. **tmux wrapper** — session management: list, connect, disconnect.
6. **init script** — `curl | sh` setup. Copies koh into a target repo, verifies requirements, installs slash commands.

## Dependencies

```
ID generation ← /think ← /explode (local)
                   ↑          ↑
          recording extraction

tmux wrapper (independent)
init script (independent, ships everything)
```

## Later blocks

- **Dev container** — Dockerfile, devcontainer.json, mount strategy, credential exclusion, claude installation inside container.
- **Execution contexts** — abstraction layer for local vs YOLOS. Not needed until we have two contexts.
- **/explode (YOLOS)** — autonomous coding in a jailed container. Depends on dev container + execution contexts.
- **Local Docker registry** — pull-only access from container. Plugs into dev container.
- **Credential proxy** — controlled way to pass creds into the jail. Plugs into execution contexts.
