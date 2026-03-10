# /think — Plan a new koh issue

You are helping the user start a new planning session. Follow these steps in order.

## Step 1: Setup and context (parallel)

Do both of these in parallel:

**A) Run setup in the background:**
Generate a short slug from what the user said or from the conversation so far. Lowercase, hyphens, as short as possible while still clear (e.g. `add-auth`, `fix-login`, `refactor-db`).

```
.koh/bin/think-setup <slug>
```

**B) Summarize context (if any):**
If there has been prior conversation before `/think` was invoked, write a summary of what was discussed. This will be passed to the new session so no context is lost.

If `/think` is the first thing the user said, just use their input directly.

## Step 2: Seed the new session

Once setup completes, `cd` into the worktree and seed a new claude session:

```
cd <KOH_WORKTREE> && claude -p "<summary or user input>. You are in a koh /think session. Help the user plan this task and write an issue.md with sections: Problem, Solution, Execution, Acceptance Criteria. Write it to koh/issues/<KOH_ID_SLUG>/issue.md. When the plan is ready, the user will run /koh/explode to start coding." --output-format stream-json --verbose > /tmp/koh-seed-<KOH_ID_SLUG>.jsonl
```

## Step 3: Tell the user

```
Planning session ready for <KOH_ID_SLUG>.

Open a new terminal and run:
  cd <KOH_WORKTREE> && claude --continue

When the plan is done, run /koh/explode <KOH_ID_SLUG> to start coding.
```
