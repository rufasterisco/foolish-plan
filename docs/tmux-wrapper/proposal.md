# tmux wrapper — implementation proposal

## What it is

A thin wrapper around tmux that exposes only the commands koh needs. All koh sessions run inside tmux so you can attach/detach at any time.

## Interface

```sh
koh/bin/tmux list                  # show running koh sessions
koh/bin/tmux connect <id-slug>     # attach to a session
koh/bin/tmux disconnect            # detach from current session
```

## Session naming

All koh tmux sessions use the prefix `koh-`:
- `koh-4-add-auth`
- `koh-7-fix-login`

This makes it easy to filter koh sessions from other tmux sessions.

## Steps

### list

- `tmux list-sessions -F '#{session_name}' | grep '^koh-'`
- Show session name, status (attached/detached), creation time
- If no sessions, say so

### connect

- `tmux attach-session -t koh-<id-slug>`
- If the session doesn't exist, error with a helpful message

### disconnect

- From inside a tmux session: `tmux detach-client`
- **Open question:** can this be triggered from outside? Or does the user just use the standard tmux detach (ctrl+b d)?
- Probably just document the tmux shortcut rather than wrapping it

## Implementation

Single script with subcommands, or three tiny scripts. Single script is simpler:

```sh
# koh/bin/tmux
case "$1" in
  list) ... ;;
  connect) ... ;;
  disconnect) ... ;;
  *) echo "Usage: koh tmux {list|connect|disconnect}" ;;
esac
```

## How /explode uses it

/explode creates the tmux session:

```sh
tmux new-session -d -s "koh-<id-slug>" -c "<worktree-path>" "claude ..."
```

The wrapper just provides a way to interact with sessions after creation.

## Open questions

1. **Disconnect** — is wrapping `tmux detach` useful, or just document ctrl+b d?
2. **Session cleanup** — should `list` show dead sessions? Should there be a `clean` command?
3. **Naming collision** — tmux session names must be unique. The `koh-<id-slug>` prefix handles this as long as IDs are unique (which they are).
