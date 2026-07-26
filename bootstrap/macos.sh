#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# macOS Bootstrap Script
# Jonathan Rae‑Brown — Golden Gate 27
# This script orchestrates the entire macOS setup process.
###############################################################################

echo "🔧 macOS bootstrap starting…"

# Detect architecture
ARCH="$(uname -m)"
echo "📐 Architecture detected: $ARCH"

# Prompt for Cloudflare API token (never stored in repo)
echo "☁️ Cloudflare Zero Trust setup requires an API token."
read -s "?Enter Cloudflare API token (input hidden): " CF_API_TOKEN
export CF_API_TOKEN

# Prompt for Git identity
read "?Git username (default: jraebrown): " GIT_USER
export GIT_USER="${GIT_USER:-jraebrown}"

read "?Git email (default: me@jraebrown.com): " GIT_EMAIL
export GIT_EMAIL="${GIT_EMAIL:-me@jraebrown.com}"

echo "👤 Using Git identity: $GIT_USER <$GIT_EMAIL>"

# Ensure dotfiles repo exists
if [[ ! -d "$HOME/dotfiles" ]]; then
  echo "📦 Cloning dotfiles repo…"
  git clone https://github.com/jraebrown/dotfiles "$HOME/dotfiles"
else
  echo "📁 dotfiles repo already present."
fi

# Move into repo
cd "$HOME/dotfiles/bootstrap"

###############################################################################
# Run modules in order
###############################################################################

echo "📦 Running APFS setup…"
source apfs.sh

echo "🍺 Installing Homebrew + packages…"
source brew.sh

echo "🔐 Setting up SSH + GitHub…"
source ssh.sh

echo "☁️ Configuring Cloudflare tunnels…"
source cloudflare.sh

echo "🔗 Linking dotfiles…"
source dotfiles.sh

echo "⚙️ Applying macOS defaults…"
source defaults.sh

###############################################################################
# Final summary
###############################################################################

echo ""
echo "✨ macOS bootstrap complete."
echo "You may now sign into iCloud, OneDrive, and Google Drive."
echo "APFS volumes CloudCache, Caches, and Work are active."
echo "Cloudflare tunnels are configured."
echo "Dotfiles are linked."
echo "SSH keys are installed and uploaded."
echo ""
echo "🚀 Reboot recommended."
