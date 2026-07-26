#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# SSH + GitHub Setup
###############################################################################

echo "🔐 SSH setup starting…"

KEY="$HOME/.ssh/id_ed25519"
PUB="$HOME/.ssh/id_ed25519.pub"

if [[ -f "$KEY" ]]; then
  echo "✔️ SSH key already exists at $KEY"
else
  echo "➕ Generating new shared ed25519 SSH key…"
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY" -N ""
fi

echo "🔧 Starting ssh-agent…"
eval "$(ssh-agent -s)"

echo "➕ Adding SSH key to agent…"
ssh-add "$KEY"

echo "👤 Configuring Git identity…"
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

###############################################################################
# GitHub authentication — non-interactive only.
# `gh auth login` with no args is an interactive menu and will hang/fail
# under curl|bash. Requires GH_TOKEN set beforehand:
#   GH_TOKEN=ghp_xxx EXTERNAL_VOLUME_NAME=Backup curl -sSL https://jraebrown.com/setup | bash
# Create a token at: https://github.com/settings/tokens (needs 'admin:public_key' scope)
###############################################################################

if gh auth status >/dev/null 2>&1; then
  echo "✔️ Already authenticated with GitHub."
elif [[ -n "${GH_TOKEN:-}" ]]; then
  echo "📤 Logging into GitHub using GH_TOKEN…"
  echo "$GH_TOKEN" | gh auth login --hostname github.com --git-protocol ssh --with-token
else
  echo "❌ Not authenticated with GitHub and no GH_TOKEN set."
  echo "   Set GH_TOKEN to a personal access token (admin:public_key scope) and rerun,"
  echo "   or run 'gh auth login' manually first in an interactive terminal."
  exit 1
fi

echo "📡 Uploading SSH key to GitHub…"
if gh ssh-key list | grep -q "$(cat "$PUB")"; then
  echo "✔️ SSH key already uploaded to GitHub."
else
  gh ssh-key add "$PUB" --title "MacBookAir"
  echo "✨ SSH key uploaded to GitHub."
fi

echo "📁 Installing SSH config…"
mkdir -p "$HOME/.ssh"
cp "$HOME/dotfiles/ssh/config" "$HOME/.ssh/config"

chmod 600 "$HOME/.ssh/config"
chmod 600 "$KEY"
chmod 644 "$PUB"

echo ""
echo "✨ SSH setup complete."
echo "Key: $KEY"
echo "GitHub identity: $GIT_USER <$GIT_EMAIL>"
echo "SSH config installed."
echo ""
