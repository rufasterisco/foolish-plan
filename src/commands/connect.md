# /connect — Connect to a running koh session

The user wants to attach to a running koh session.

First, check that the session exists by running:

```
.koh/bin/koh-tmux list
```

If the session exists, tell the user:

1. Open a new terminal (in VS Code: `ctrl+shift+backtick`)
2. Run: `.koh/bin/koh-tmux connect <id-slug>`
3. To detach from the session: `ctrl+b d`

You cannot attach from this terminal — tmux would take over the claude session. A separate terminal is needed.

> **Future:** a VS Code extension could spawn a new terminal and attach automatically. For now, this is a manual step.
