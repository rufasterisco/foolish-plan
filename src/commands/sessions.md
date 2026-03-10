# /sessions — List running koh sessions

Run the following command to see all running koh sessions:

```
.koh/bin/koh-tmux list
```

Show the output to the user.

If there are running sessions, remind the user how to connect:

1. Open a new terminal (in VS Code: `ctrl+shift+backtick`)
2. Run: `.koh/bin/koh-tmux connect <id-slug>`
3. To detach from the session: `ctrl+b d`

> **Note:** connecting to a session requires a separate terminal — it can't be done from this claude session because tmux would take over the terminal. A VS Code extension could automate this in the future.
