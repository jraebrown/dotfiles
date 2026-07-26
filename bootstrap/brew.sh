#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# Homebrew + Core Tools Installer
###############################################################################

echo "🍺 Homebrew installation starting…"

###############################################################################
# Get sudo access via the real terminal, not the curl|bash pipe's stdin
###############################################################################

echo "🔐 Requesting sudo access (needed for Homebrew install)…"
sudo -v < /dev/tty

# Keep sudo timestamp alive in background while this script runs
( while true; do sudo -n -v; sleep 60; done ) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

###############################################################################
# Install Homebrew (ARM-aware)
###############################################################################

if [[ "$(uname -m)" == "arm64" ]]; then
  if [[ ! -d "/opt/homebrew" ]]; then
    echo "➕ Installing Homebrew for Apple Silicon…"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "✔️ Homebrew already installed."
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "⚠️ Intel Mac detected — adjust Homebrew paths manually."
fi

###############################################################################
# Install core packages
###############################################################################

echo "📦 Installing core packages…"
brew install python node fzf nano gh cloudflared jq wget curl tmux

###############################################################################
# Install zsh4humans
###############################################################################

echo "💡 Installing zsh4humans…"
if [[ ! -d "${XDG_CACHE_HOME:-$HOME/.cache}/z4h" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"
else
  echo "✔️ zsh4humans already installed."
fi

###############################################################################
# Install nano syntax highlighting
###############################################################################

echo "🖍️ Installing nano syntax highlighting…"
curl -fsSL https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh

###############################################################################
# Install fzf keybindings + completion
###############################################################################

echo "⚙️ Configuring fzf keybindings…"
if [[ -f "/opt/homebrew/opt/fzf/install" ]]; then
  yes | /opt/homebrew/opt/fzf/install --key-bindings --completion --no-update-rc
fi

echo ""
echo "✨ Homebrew + core tools installed."
echo ""
