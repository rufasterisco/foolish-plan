# /think — Plan a new koh issue

You are helping the user plan a new coding task. Follow these steps in order.

## Step 1: Setup

Generate a short slug from what the user said or from the conversation so far. Lowercase, hyphens, as short as it can be while still clear (e.g. `add-auth`, `fix-login`, `refactor-db`).

Run:
```
.koh/bin/think-setup <slug>
```

Save the KEY=VALUE output — you'll need `KOH_ID_SLUG`, `KOH_WORKTREE`, and `KOH_ISSUE_DIR`.

## Step 2: Write the execution plan

Together with the user, build an execution plan. Write `issue.md` at `<KOH_ISSUE_DIR>/issue.md`:

```markdown
# <KOH_ID_SLUG>: <short title>

## Problem
What needs to be done and why.

## Solution
The approach — what will be built/changed.

## Execution
Step-by-step plan. Be specific about files, functions, and changes.

## Acceptance criteria
How to verify the work is done correctly.
```

## Step 3: Finish

After the user confirms the plan looks good, run:
```
.koh/bin/think-finish <KOH_ID_SLUG> <KOH_WORKTREE>
```

Tell the user they can now run `/koh/explode <KOH_ID_SLUG>` to start coding.
