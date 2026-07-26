#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# Homebrew + Core Tools Installer
# Installs Homebrew, Python, Node, fzf, nano syntax highlighting, gh, cloudflared
# Installs zsh4humans and configures shell environment.
###############################################################################

echo "🍺 Homebrew installation starting…"

###############################################################################
# Install Homebrew (ARM-aware)
###############################################################################

if [[ "$(uname -m)" == "arm64" ]]; then
  if [[ ! -d "/opt/homebrew" ]]; then
    echo "➕ Installing Homebrew for Apple Silicon…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "✔️ Homebrew already installed."
  fi

  # Load Homebrew environment
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "⚠️ Intel Mac detected — adjust Homebrew paths manually."
fi

###############################################################################
# Install core packages
###############################################################################

echo "📦 Installing core packages…"

brew install \
  python \
  node \
  fzf \
  nano \
  gh \
  cloudflared \
  jq \
  wget \
  curl \
  tmux

###############################################################################
# Install apps + AI CLIs
###############################################################################

echo "🧰 Installing apps…"

brew install --cask iterm2
brew install gemini-cli          # NOTE: deprecated 2026-12-18, replacement is antigravity-cli
brew install --cask google-gemini
brew install --cask microsoft-365-copilot
brew install --cask claude

###############################################################################
# Restore iTerm2 preferences from dotfiles
# One-time step on your CURRENT machine before this is useful:
#   defaults write com.googlecode.iterm2 PrefsCustomFolder \
#     -string "$HOME/dotfiles/iterm2"
#   defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
#   Then Preferences > General > Settings > "Save Settings to Folder" once
#   to drop com.googlecode.iterm2.plist into ~/dotfiles/iterm2/, commit it.
###############################################################################

if [[ -f "$HOME/dotfiles/iterm2/com.googlecode.iterm2.plist" ]]; then
  echo "🖥️  Restoring iTerm2 preferences from dotfiles…"
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/dotfiles/iterm2"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
else
  echo "⚠️  No iTerm2 prefs found in dotfiles yet — run the one-time export first (see comment above)."
fi

###############################################################################
# Install zsh4humans
###############################################################################

echo "💡 Installing zsh4humans…"

# Only install if not already present
if [[ ! -d "$HOME/.zsh4humans" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"
else
  echo "✔️ zsh4humans already installed."
fi

###############################################################################
# Install nano syntax highlighting
###############################################################################

echo "🖍️ Installing nano syntax highlighting…"

NANO_SYNTAX_DIR="$HOME/.nano"
mkdir -p "$NANO_SYNTAX_DIR"

curl -fsSL https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh

###############################################################################
# Install fzf keybindings + completion
###############################################################################

echo "⚙️ Configuring fzf keybindings…"

if [[ -f "/opt/homebrew/opt/fzf/install" ]]; then
  yes | /opt/homebrew/opt/fzf/install --key-bindings --completion --no-update-rc
fi

###############################################################################
# Summary
###############################################################################

echo ""
echo "✨ Homebrew + core tools installed."
echo "Installed:"
echo "  - Python"
echo "  - Node"
echo "  - fzf"
echo "  - nano + syntax highlighting"
echo "  - gh (GitHub CLI)"
echo "  - cloudflared"
echo "  - jq, wget, curl, tmux"
echo "  - zsh4humans"
echo ""
