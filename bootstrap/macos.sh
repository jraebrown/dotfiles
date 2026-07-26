#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# macOS Bootstrap Script (Optimized)
# Jonathan Rae‑Brown — Golden Gate 27
# Orchestrates the entire macOS setup with parallel execution.
# 
# Performance improvements:
# - Runs apfs, brew, cloudflare, and ssh in parallel (I/O-bound tasks)
# - Sequential dependency: apfs → then brew/ssh/cloudflare → dotfiles → defaults
# - Removed redundant Spotlight config (handled by spotlight.sh)
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
# Phase 1: APFS (must complete before others)
###############################################################################

echo "📦 Running APFS setup…"
source apfs.sh

###############################################################################
# Phase 2: Run I/O-bound tasks in parallel
# These can run concurrently safely (isolated side effects)
###############################################################################

echo "🍺 Installing Homebrew + packages (parallel)…"
source brew.sh &
BREW_PID=$!

echo "🔐 Setting up SSH + GitHub (parallel)…"
source ssh.sh &
SSH_PID=$!

echo "☁️ Configuring Cloudflare tunnels (parallel)…"
source cloudflare.sh &
CF_PID=$!

# Wait for all parallel tasks
wait $BREW_PID || {
  echo "❌ Homebrew setup failed"
  exit 1
}
wait $SSH_PID || {
  echo "❌ SSH setup failed"
  exit 1
}
wait $CF_PID || {
  echo "❌ Cloudflare setup failed"
  exit 1
}

echo "✅ All parallel tasks completed."

###############################################################################
# Phase 3: Sequential tasks (depend on phases 1-2)
###############################################################################

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
