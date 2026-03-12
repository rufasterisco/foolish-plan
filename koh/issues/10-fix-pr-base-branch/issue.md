---
id: 10-fix-pr-base-branch
branch: 10-fix-pr-base-branch
worktree: /Users/francesco/projects/koh/.koh-worktrees/10-fix-pr-base-branch
think-recording: ./think-recording.jsonl
explode-recording: ./explode-recording.jsonl
---

# 10-fix-pr-base-branch: PRs target master instead of dev

## Problem

When Claude opens a PR from a think/explode session, it targets `master` instead of `dev`. The user's main branch is `dev`.

## Root cause

In `.git/config`, the `dev` branch has:
```
[branch "dev"]
    vscode-merge-base = origin/master
```

This is what `gh pr create` reads as the default base. Feature branches correctly set `vscode-merge-base = origin/dev`, but the `dev` branch itself points to `origin/master`.

No koh scripts or prompts explicitly set `--base` on `gh pr create` — they rely on git's default, which is wrong.

## Solution

Fix `.git/config` — change `dev` branch's `vscode-merge-base` to `origin/dev`.

No preventive fix needed: GitHub's default branch is already `dev`, so new clones will target `dev` by default. The `vscode-merge-base = origin/master` was a leftover from when `master` was the default branch.

## Execution

1. `git config branch.dev.vscode-merge-base origin/dev` ✅

## Acceptance criteria
- PRs created from koh sessions target `dev` by default
