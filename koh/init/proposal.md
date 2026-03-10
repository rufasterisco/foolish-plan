# init script — implementation proposal

## What it is

A setup script that installs koh into a target repository. The user runs it once via curl, and it sets up everything needed to use /think and /explode in that repo.

## Interface

```sh
# from inside any git repo:
curl -fsSL https://raw.githubusercontent.com/rufasterisco/koh/master/init.sh | sh
```

## What it does

### Step 1: verify requirements

Check that the following are available:
- `git` — for worktrees, branches, commits
- `claude` — Claude Code CLI
- `tmux` — for session management
- `jq` — for parsing session logs

If anything is missing, print what's needed and exit.

### Step 2: verify context

- Check we're inside a git repo (`git rev-parse --git-dir`)
- Check we're at the repo root (or navigate to it)

### Step 3: create directory structure

```
.claude/koh/          # koh scripts and slash commands (inside claude's config dir)
koh/                  # koh data directory (issue files, recordings)
  issues/             # created empty, ready for /think
```

### Step 4: copy scripts

Copy from the koh repo (fetched via curl or git clone) into the target repo:
- `koh/bin/think`
- `koh/bin/explode`
- `koh/bin/tmux`
- `koh/lib/id.sh`
- `koh/lib/recording.sh`

### Step 5: install slash commands

Claude Code slash commands live in `.claude/commands/`. Install:
- `.claude/commands/think.md` — orchestration prompt for planning an issue
- `.claude/commands/explode.md` — orchestration prompt for running a coding session

**Architecture:** slash commands are markdown prompts — they tell claude which shell scripts to run, in what order, and how to handle errors. Shell scripts do the deterministic work (create branch, copy files, extract recording, commit). Claude is the runtime that executes the slash commands — it's the smart glue between dumb, reliable scripts. This makes the scripts optimizable and testable, while the markdown layer can evolve to handle more complex orchestration (conditional steps, error recovery, etc.) without changing the scripts.

### Step 6: update .gitignore

Add koh-specific entries if not already present:
- Worktree locations (if they live inside the repo)
- Temporary files

### Step 7: confirm

Print what was set up and next steps.

## Open questions

1. **Script location** — do scripts live inside the target repo (committed) or in a global location? If committed, they're versioned with the project. If global, they're shared across projects.
2. **Updates** — how does the user update koh? Re-run init? A separate `koh update` command?
3. **koh/ in .gitignore?** — issue files and recordings should be committed (that's the point). But worktree paths shouldn't. Need to be precise about what gets ignored.
