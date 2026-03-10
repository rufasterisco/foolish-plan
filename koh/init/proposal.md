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
- `.claude/commands/think.md` — prompt that calls `koh/bin/think`
- `.claude/commands/explode.md` — prompt that calls `koh/bin/explode`

**Open question:** slash commands are markdown prompts, not shell scripts. How do they invoke the shell scripts? Might need to be hooks or a different mechanism. Needs investigation.

### Step 6: update .gitignore

Add koh-specific entries if not already present:
- Worktree locations (if they live inside the repo)
- Temporary files

### Step 7: confirm

Print what was set up and next steps.

## Open questions

1. **Slash commands vs scripts** — Claude Code slash commands are markdown prompts, not executables. How do /think and /explode get triggered? Are they slash commands that tell claude to run a shell script? Or are they standalone scripts the user runs directly (not through claude)?
2. **Script location** — do scripts live inside the target repo (committed) or in a global location? If committed, they're versioned with the project. If global, they're shared across projects.
3. **Updates** — how does the user update koh? Re-run init? A separate `koh update` command?
4. **koh/ in .gitignore?** — issue files and recordings should be committed (that's the point). But worktree paths shouldn't. Need to be precise about what gets ignored.
