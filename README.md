> *"Put these foolish ambitions to rest."*
> — Margit, the Fell Omen

# foolish-plan

An organized way to record what happens in coding sessions with a coding agent. Currently supports Claude Code.

## Setup

Install via:

```sh
curl -fsSL https://raw.githubusercontent.com/rufasterisco/foolish-plan/master/install.sh | sh
```

The installer will:
- Verify all requirements are in place (Claude Code, git, etc.)
- Install custom slash commands into Claude Code

## How it works

Each coding session produces two artifacts that get committed alongside the code:

- **Issue file** — describes the intent and plan for the session
  - Problem
  - Solution
  - Execution
  - Acceptance criteria
- **Recording file** — a log of the reasoning throughout the session, whether it's a human-AI conversation or the AI working autonomously
