# /explode — Start a coding session

You are helping the user launch a coding session for an existing koh issue.

## Step 1: Identify the issue

The user should have provided an id-slug as an argument: `/explode <id-slug>`

If they didn't, ask them which issue to work on.

## Step 2: Launch

Run the explode script:
```
.koh/bin/explode <id-slug>
```

This will:
1. Validate the worktree and issue file exist
2. Seed a new claude session with the issue's execution plan
3. Launch an interactive session in a tmux window

The script will print how to connect to the tmux session.

## Step 3: Tell the user

After the script runs, tell the user:
- The tmux session name (e.g. `koh-4-add-auth`)
- How to connect: `koh-tmux connect <id-slug>`
- How to disconnect: `ctrl+b d`
- When they're done, just `/exit` from claude inside the tmux session — the recording will be extracted and committed automatically.
