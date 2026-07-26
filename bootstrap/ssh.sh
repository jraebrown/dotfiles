#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# SSH + GitHub Setup
# Generates shared ed25519 key, configures ssh-agent, uploads key to GitHub,
# installs SSH config, and sets Git identity.
###############################################################################

echo "🔐 SSH setup starting…"

KEY="$HOME/.ssh/id_ed25519"
PUB="$HOME/.ssh/id_ed25519.pub"

###############################################################################
# Generate shared ed25519 key if missing
###############################################################################

if [[ -f "$KEY" ]]; then
  echo "✔️ SSH key already exists at $KEY"
else
  echo "➕ Generating new shared ed25519 SSH key…"
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY" -N ""
fi

###############################################################################
# Start ssh-agent and add key
###############################################################################

echo "🔧 Starting ssh-agent…"
eval "$(ssh-agent -s)"

echo "➕ Adding SSH key to agent…"
ssh-add "$KEY"

###############################################################################
# Git identity
###############################################################################

echo "👤 Configuring Git identity…"

git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

###############################################################################
# GitHub authentication (passkey / iCloud Keychain)
###############################################################################

echo "📤 Logging into GitHub (passkey recommended)…"
gh auth login

###############################################################################
# Upload SSH key to GitHub
###############################################################################

echo "📡 Uploading SSH key to GitHub…"

# Check if key already exists on GitHub
if gh ssh-key list | grep -q "$(cat "$PUB")"; then
  echo "✔️ SSH key already uploaded to GitHub."
else
  gh ssh-key add "$PUB" --title "MacBookAir"
  echo "✨ SSH key uploaded to GitHub."
fi

###############################################################################
# Install SSH config
###############################################################################

echo "📁 Installing SSH config…"

mkdir -p "$HOME/.ssh"
cp "$HOME/dotfiles/ssh/config" "$HOME/.ssh/config"

chmod 600 "$HOME/.ssh/config"
chmod 600 "$KEY"
chmod 644 "$PUB"

###############################################################################
# Summary
###############################################################################

echo ""
echo "✨ SSH setup complete."
echo "Key: $KEY"
echo "GitHub identity: $GIT_USER <$GIT_EMAIL>"
echo "SSH config installed."
echo ""
