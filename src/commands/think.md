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

The setup script created `<KOH_ISSUE_DIR>/issue.md` from a template. If there has been prior conversation, read the template and fill in as much as possible from what was discussed.

## Step 3: Seed the new session

```
cd <KOH_WORKTREE> && claude -p "<summary or user input>. You are in a koh /think session. Help the user plan this task. The issue template is at koh/issues/<KOH_ID_SLUG>/issue.md — read it, fill in all sections. When the plan is ready, the user will run /koh/explode to start coding." --output-format stream-json --verbose > <KOH_ISSUE_DIR>/.seed-output.jsonl
```

## Step 4: Tell the user

Tell the user the planning session is ready. To open it:

  Cmd+Shift+P → "Run Task" → koh-think-<KOH_ID_SLUG>

This opens a new terminal with claude in the worktree, with all context loaded.

When the plan is done, run `/koh/explode <KOH_ID_SLUG>` to start coding.
