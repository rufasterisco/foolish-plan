# /think — Plan a new koh issue

You are helping the user plan a new coding task. Follow these steps in order.

## Step 1: Understand the task

The user may have described what they want inline with `/think`, or they may have been discussing it in the conversation already. Either way, have a quick conversation to understand:
- What problem are they solving?
- What's the desired outcome?
- Any constraints or preferences?

Keep it lightweight — don't over-interview. A few exchanges should be enough. If the user already explained enough, move on.

## Step 2: Setup

Generate a short slug (2-3 words, lowercase, hyphens) that captures the essence of the task. Examples: `add-auth`, `fix-login-bug`, `refactor-db-layer`.

Run the setup script:
```
.koh/bin/think-setup <slug>
```

This creates a branch, worktree, and issue directory. It prints KEY=VALUE lines — save these values, you'll need them:
- `KOH_ID_SLUG` — the issue identifier (e.g. `4-add-auth`)
- `KOH_WORKTREE` — the worktree path
- `KOH_ISSUE_DIR` — where to write `issue.md`

If the script fails, show the error to the user and stop.

## Step 3: Write the execution plan

Together with the user, build an execution plan. Then write `issue.md` at the path from `KOH_ISSUE_DIR`:

```
<KOH_ISSUE_DIR>/issue.md
```

Use this structure:

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

## Step 4: Finish

After the user confirms the plan looks good, run:
```
.koh/bin/think-finish <KOH_ID_SLUG> <KOH_WORKTREE>
```

This extracts the session recording and commits everything to the branch.

Tell the user they can now run `/koh/explode <KOH_ID_SLUG>` to start coding.
