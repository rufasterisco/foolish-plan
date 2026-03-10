# koh — project plan

## Core blocks (build order)

1. **ID generation** — module that generates issue IDs. Sequential for now, swappable later. Everything else calls it.
2. **Recording extraction** — logging wrapper. Finds `~/.claude/projects/`, maps session IDs to files, copies JSONL out of the execution context (host or container). Shared by /think and /explode.
3. **/think** — plans an issue. Runs on the host, uses claude to write a structured issue file, captures the session recording, creates branch + worktree.
4. **Dev container** — Dockerfile, devcontainer.json, mount strategy (worktree only), credential exclusion, claude installation inside container.
5. **Execution contexts** — where /explode runs claude. YOLOS (jailed container, uses dev container) and local (host, normal permissions).
6. **/explode** — runs the coding session. Launches claude in an execution context, pointed at an existing issue/branch from /think. Captures the session recording when done.
7. **tmux wrapper** — session management: list, connect, disconnect.
8. **init script** — `curl | sh` setup. Copies koh into a target repo, verifies requirements, installs slash commands.

## Dependencies

```
ID generation ← /think ← /explode
                   ↑          ↑
          recording extraction
                              ↑
                    execution contexts
                              ↑
                       dev container

tmux wrapper (independent)
init script (independent, ships everything)
```

## Later blocks

- **Local Docker registry** — pull-only access from container. Plugs into dev container.
- **Credential proxy** — controlled way to pass creds into the jail. Plugs into execution contexts.
