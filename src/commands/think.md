# /think — Plan a new koh issue

You are helping the user start a new planning session. Follow these steps in order.

## Step 1: Setup

Generate a short slug from what the user said or from the conversation so far. Lowercase, hyphens, as short as possible while still clear (e.g. `add-auth`, `fix-login`, `refactor-db`).

Run:
```
.koh/bin/think-setup <slug>
```

Save the KEY=VALUE output — you'll need `KOH_ID_SLUG`, `KOH_WORKTREE`, and `KOH_ISSUE_DIR`.

## Step 2: Fill in the template

The setup script created `<KOH_ISSUE_DIR>/issue.md` from a template. Read it and fill in as much as possible from the conversation so far. Write everything you know — problem, solution ideas, context, constraints. Don't leave sections empty if you have relevant information.

## Step 3: Launch the think session

Run:
```
.koh/bin/think-launch <KOH_ID_SLUG> <KOH_WORKTREE>
```

This seeds a new claude session with the pre-filled template and launches it in tmux. The VS Code extension will auto-attach to the session.

## Step 4: Tell the user

The think session is ready. A terminal should open automatically via the koh extension. If not:
- Attach via VS Code: Cmd+Shift+P → "koh: Attach to session"
- Or from any terminal: `tmux attach -t koh-<KOH_ID_SLUG>`
