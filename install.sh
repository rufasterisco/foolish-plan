#!/bin/bash
# koh install script.
# Run from inside any git repo to install koh:
#   curl -fsSL https://raw.githubusercontent.com/rufasterisco/koh/master/install.sh | sh
#
# Or if you have the koh repo cloned:
#   /path/to/koh/install.sh

set -euo pipefail

echo "=== koh init ==="
echo ""

# --- Step 1: verify requirements ---

missing=""
for cmd in git claude tmux jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing="$missing $cmd"
  fi
done

if [ -n "$missing" ]; then
  echo "ERROR: missing required commands:$missing" >&2
  echo "Please install them and try again." >&2
  exit 1
fi

# --- Step 2: verify context ---

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository" >&2
  echo "Run this script from inside the repo you want to set up." >&2
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

echo "Repo: $repo_root"

# --- Locate koh source files ---
# If run via curl, we need to download them.
# If run from a cloned koh repo, they're relative to this script.

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
if [ -f "$SCRIPT_PATH" ]; then
  # Running from a file — assume koh repo is cloned
  KOH_SRC="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)/src"
else
  # Running from pipe (curl | sh) — download to tmp
  KOH_SRC=$(mktemp -d)
  trap "rm -rf $KOH_SRC" EXIT
  echo "Downloading koh..."
  git clone --depth 1 https://github.com/rufasterisco/koh.git "$KOH_SRC/../koh-tmp" 2>/dev/null
  KOH_SRC="$KOH_SRC/../koh-tmp/src"
fi

if [ ! -d "$KOH_SRC/lib" ] || [ ! -d "$KOH_SRC/bin" ]; then
  echo "ERROR: could not find koh source files at $KOH_SRC" >&2
  exit 1
fi

# --- Step 3: create directory structure ---

mkdir -p .koh/bin .koh/lib koh/issues

# --- Step 4: copy scripts ---

cp "$KOH_SRC/lib/guards.sh"    .koh/lib/guards.sh
cp "$KOH_SRC/lib/id.sh"        .koh/lib/id.sh
cp "$KOH_SRC/lib/recording.sh" .koh/lib/recording.sh
cp "$KOH_SRC/bin/think-setup"  .koh/bin/think-setup
cp "$KOH_SRC/bin/think-finish" .koh/bin/think-finish
cp "$KOH_SRC/bin/explode"      .koh/bin/explode
cp "$KOH_SRC/bin/koh-tmux"     .koh/bin/koh-tmux

chmod +x .koh/bin/*

echo "Scripts installed to .koh/"

# --- Step 5: install slash commands ---

mkdir -p .claude/commands/koh

cp "$KOH_SRC/commands/think.md"    .claude/commands/koh/think.md
cp "$KOH_SRC/commands/explode.md"  .claude/commands/koh/explode.md
cp "$KOH_SRC/commands/sessions.md" .claude/commands/koh/sessions.md
cp "$KOH_SRC/commands/connect.md"  .claude/commands/koh/connect.md

echo "Slash commands installed to .claude/commands/koh/"

# --- Step 6: update .gitignore ---

gitignore_entries=(
  "# koh worktrees"
  ".koh-worktrees/"
)

touch .gitignore
for entry in "${gitignore_entries[@]}"; do
  if ! grep -qF "$entry" .gitignore; then
    echo "$entry" >> .gitignore
  fi
done

echo ".gitignore updated"

# --- Step 7: confirm ---

echo ""
echo "=== koh installed ==="
echo ""
echo "Installed:"
echo "  .koh/bin/          scripts"
echo "  .koh/lib/          shared libraries"
echo "  .claude/commands/  slash commands (/think, /explode)"
echo "  koh/issues/        issue files (committed with your code)"
echo ""
echo "Next steps:"
echo "  1. Commit the koh files: git add .koh .claude/commands koh .gitignore"
echo "  2. Start planning: /think <slug>"
echo ""
