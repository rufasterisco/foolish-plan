---
id: 3-fix-think-reread
branch: 3-fix-think-reread
worktree: /Users/francesco/projects/koh/.koh-worktrees/3-fix-think-reread
think-recording: ./think-recording.jsonl
explode-recording: ./explode-recording.jsonl
---

# 3-fix-think-reread: Fix think session behaviour

## Problem

Two issues with the think flow:

### 1. Think session Claude re-reads the issue it already has
When `think-launch` starts a Claude session, `issue.md` is passed via `--append-system-prompt-file`. But the launched Claude doesn't realize it already has the issue content. It wastes time reading the issue file and exploring the project before responding.

### 2. The `/think` slash command stops to ask questions instead of just running
`src/commands/think.md` tells Claude to generate a slug, run setup, fill the template, then launch. In practice, Claude stops to reason with the user or ask clarifying questions at each step instead of just executing the scripts and moving on.

## Solution

### Fix 1: Update `src/prompts/think-launch.md`
Make the system prompt explicitly tell the launched Claude:
- The issue content is already included above via system prompt — do NOT re-read `issue.md`
- Use the Edit tool to update `issue.md` directly without reading it first (it's already in context)
- Start working with the user immediately, no file exploration needed

### Fix 2: Update `src/commands/think.md`
Make the `/think` slash command more directive:
- Tell Claude to just run the scripts without stopping to discuss or ask permission
- Generate the slug from context and run `think-setup` immediately
- Fill what it can from the conversation, then run `think-launch` immediately
- Only stop if a script errors — not to ask "is this slug ok?" or "shall I proceed?"

## Execution

1. Edit `src/prompts/think-launch.md` — add explicit instructions that issue content is already in the system prompt, don't re-read it, don't explore the codebase
2. Edit `src/commands/think.md` — rewrite to be more imperative: "just do it, don't ask"
3. Test by running `/think` on a test issue and verifying Claude doesn't stop to ask or re-read

## Files to change
- `src/prompts/think-launch.md`
- `src/commands/think.md`

## Acceptance criteria
- When a think session launches, Claude responds directly using the issue content from its system prompt without re-reading files
- When user runs `/think`, Claude generates a slug, runs setup, fills the template, and launches — all without stopping to ask the user for confirmation
