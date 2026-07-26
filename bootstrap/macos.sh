#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# macOS Bootstrap Script
# Jonathan Rae‑Brown
#
# No interactive prompts — this must survive `curl | bash`, where stdin is
# the piped script itself, not your keyboard. Set these as env vars BEFORE
# running if you want non-default values, e.g.:
#   GIT_USER=jraebrown GIT_EMAIL=me@jraebrown.com EXTERNAL_VOLUME_NAME=Backup \
#     curl -sSL https://jraebrown.com/setup | bash
###############################################################################

echo "🔧 macOS bootstrap starting…"

ARCH="$(uname -m)"
echo "📐 Architecture detected: $ARCH"

GIT_USER="${GIT_USER:-jraebrown}"
GIT_EMAIL="${GIT_EMAIL:-me@jraebrown.com}"
export GIT_USER GIT_EMAIL

echo "👤 Using Git identity: $GIT_USER <$GIT_EMAIL>"

if [[ -n "${CF_API_TOKEN:-}" ]]; then
  echo "☁️ Cloudflare API token provided via env var."
else
  echo "☁️ No CF_API_TOKEN set — cloudflare.sh will prompt for browser login instead."
fi
export CF_API_TOKEN="${CF_API_TOKEN:-}"

# Note: 'setup' (the outer installer) already clones this repo before
# calling this script — no need to clone again here.
cd "$HOME/dotfiles/bootstrap"

echo "📦 Skipping APFS/cache relocation — not run at boot anymore."
echo "   Run 'check-cache-size' manually anytime to monitor Caches usage."

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

echo ""
echo "✨ macOS bootstrap complete."
echo "You may now sign into iCloud, OneDrive, and Google Drive."
echo "Cloudflare tunnels are configured. Dotfiles are linked."
echo ""
echo "🚀 Reboot recommended."