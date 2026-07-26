#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# Dotfiles Linking Script
# Uses a simple, deterministic symlink method.
# Safe to run multiple times (idempotent).
###############################################################################

echo "🔗 Linking dotfiles…"

DOTFILES="$HOME/dotfiles"

###############################################################################
# Helper function
###############################################################################

link() {
  local src="$DOTFILES/$1"
  local dest="$HOME/$2"

  mkdir -p "$(dirname "$dest")"

  ln -sf "$src" "$dest"
  echo "✔️ Linked $src → $dest"
}

###############################################################################
# ZSH
###############################################################################

link "zsh/.zshrc" ".zshrc"
link "zsh/zsh4humans.conf" ".config/zsh/zsh4humans.conf"
link "zsh/aliases.zsh" ".config/zsh/aliases.zsh"
link "zsh/env.zsh" ".config/zsh/env.zsh"

###############################################################################
# Git
###############################################################################

link "git/.gitconfig" ".gitconfig"
link "git/.gitignore_global" ".gitignore_global"

###############################################################################
# SSH
###############################################################################

mkdir -p "$HOME/.ssh"
link "ssh/config" ".ssh/config"

###############################################################################
# macOS Spotlight rules (macOS only)
###############################################################################

if [[ "$(uname -s)" == "Darwin" ]]; then
  link "macos/spotlight.sh" ".config/macos/spotlight.sh"
fi

###############################################################################
# Linux (Debian / rPi)
###############################################################################

if [[ "$(uname -s)" == "Linux" ]]; then
  link "linux/debian.sh" ".config/linux/debian.sh"
fi

###############################################################################
# Helper scripts (added to PATH)
###############################################################################

mkdir -p "$HOME/.local/bin"

link "scripts/bin/link-dotfiles" ".local/bin/link-dotfiles"
link "scripts/bin/mount-rpi" ".local/bin/mount-rpi"
link "scripts/bin/update-system" ".local/bin/update-system"
link "scripts/bin/brew-sync" ".local/bin/brew-sync"

###############################################################################
# Summary
###############################################################################

echo ""
echo "✨ Dotfiles linked successfully."
echo "All symlinks are active and up to date."
echo ""
