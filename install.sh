#!/bin/bash
# koh install script.
# Run from inside any git repo to install koh:
#   curl -fsSL https://raw.githubusercontent.com/rufasterisco/koh/master/install.sh | sh
#
# Or if you have the koh repo cloned:
#   /path/to/koh/install.sh

set -euo pipefail

echo "=== koh ==="
echo ""

# --- Step 1: verify requirements ---

missing=""
for cmd in git claude tmux jq gitleaks; do
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
  KOH_ROOT="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  KOH_SRC="$KOH_ROOT/src"
else
  # Running from pipe (curl | sh) — download to tmp
  KOH_ROOT=$(mktemp -d)
  trap "rm -rf $KOH_ROOT" EXIT
  echo "Downloading koh..."
  git clone --depth 1 https://github.com/rufasterisco/koh.git "$KOH_ROOT" 2>/dev/null
  KOH_SRC="$KOH_ROOT/src"
fi

if [ ! -d "$KOH_SRC/lib" ] || [ ! -d "$KOH_SRC/bin" ]; then
  echo "ERROR: could not find koh source files at $KOH_SRC" >&2
  exit 1
fi

# --- Install koh tooling ---
# Overwrites scripts, libs, templates, and slash commands.
# Never touches user content (koh/issues/, worktrees, branches).

install_tooling() {
  mkdir -p .koh/bin .koh/lib .koh/templates .koh/prompts .koh/settings

  for f in "$KOH_SRC"/lib/*; do
    cp "$f" ".koh/lib/$(basename "$f")"
  done
  for f in "$KOH_SRC"/bin/*; do
    cp "$f" ".koh/bin/$(basename "$f")"
  done

  chmod +x .koh/bin/*

  cp "$KOH_SRC/templates/issue.md" .koh/templates/issue.md
  cp "$KOH_SRC/prompts/think-launch.md" .koh/prompts/think-launch.md
  cp "$KOH_SRC/prompts/explode.md"      .koh/prompts/explode.md
  cp "$KOH_SRC/settings/worktree-settings.json" .koh/settings/worktree-settings.json

  mkdir -p .claude/commands/koh

  cp "$KOH_SRC/commands/think.md"    .claude/commands/koh/think.md
  cp "$KOH_SRC/commands/explode.md"  .claude/commands/koh/explode.md
  cp "$KOH_SRC/commands/cleanup.md" .claude/commands/koh/cleanup.md

  # --- Update .gitignore ---

  local gitignore_entries=(
    "# koh"
    ".koh/"
    ".koh-worktrees/"
    ".claude/commands/koh/"
  )

  touch .gitignore
  for entry in "${gitignore_entries[@]}"; do
    if ! grep -qF "$entry" .gitignore; then
      echo "$entry" >> .gitignore
    fi
  done

  # --- Merge koh allow rules into .claude/settings.local.json ---

  local settings=".claude/settings.local.json"
  local koh_rules='["Bash(.koh/bin/*)", "Edit(.koh-worktrees/**)"]'

  if [ -f "$settings" ]; then
    # Merge: add koh rules that aren't already present
    local updated
    updated=$(jq --argjson rules "$koh_rules" '
      .permissions.allow = ((.permissions.allow // []) + $rules | unique)
    ' "$settings")
    echo "$updated" > "$settings"
  else
    # Create with just the koh rules
    jq -n --argjson rules "$koh_rules" '
      {permissions: {allow: $rules}}
    ' > "$settings"
  fi
}

# --- Install VS Code extension ---

install_extension() {
  if ! command -v code >/dev/null 2>&1; then
    echo "  VS Code CLI not found, skipping extension install."
    return 0
  fi

  local vsix="$KOH_ROOT/vscode-extension/koh-0.1.0.vsix"
  if [ ! -f "$vsix" ]; then
    echo "  VS Code extension package not found, skipping."
    return 0
  fi

  code --install-extension "$vsix" --force >/dev/null 2>&1
  echo "  VS Code extension installed (koh: Attach to session)."
}

# --- Check if already installed ---

if [ -d ".koh/bin" ] && [ -d ".claude/commands/koh" ]; then
  echo "koh is already installed."
  printf "\033[31mUpdate?\033[0m [y/N] "
  read -r answer
  if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
    echo "Aborted."
    exit 0
  fi

  echo ""
  install_tooling
  install_extension
  echo ""
  echo "=== koh updated ==="
  echo ""
  printf "Use \033[36m/koh:think\033[0m to plan, \033[36m/koh:explode\033[0m to code.\n"
  echo ""
  exit 0
fi

# --- Fresh install ---

echo ""
echo "Installing koh..."

install_tooling
mkdir -p koh/issues


# --- VS Code extension (optional) ---

if command -v code >/dev/null 2>&1; then
  printf "Install VS Code extension (koh: Attach to session)? [y/N] "
  read -r answer
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    install_extension
  fi
fi

echo ""
echo "=== koh installed ==="
echo ""
echo "Commit the koh files:"
echo "  git add .koh .claude/commands koh .gitignore"
echo ""
echo "Then use /koh:think to plan, /koh:explode to code."
echo ""
