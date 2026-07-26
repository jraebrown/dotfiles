#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# External Cache/Cloud Offload Setup
# Moves ~/Library/Caches, system caches, and cloud-sync scratch space onto
# an external drive so the internal SSD doesn't fill up. Replaces the old
# same-container APFS volume approach, which did not actually save space.
###############################################################################

# EDIT THIS to match your external drive's volume name exactly.
EXTERNAL_VOLUME="/Volumes/Backup"


echo "💾 External offload setup starting…"

if [[ ! -d "$EXTERNAL_VOLUME" ]]; then
  echo "❌ External drive not found at $EXTERNAL_VOLUME"
  echo "   Plug it in, or fix EXTERNAL_VOLUME at the top of this script."
  exit 1
fi

###############################################################################
# Prepare directories on external drive
###############################################################################

mkdir -p "$EXTERNAL_VOLUME/Caches/user"
mkdir -p "$EXTERNAL_VOLUME/Caches/system"
mkdir -p "$EXTERNAL_VOLUME/CloudCache/iCloud"
mkdir -p "$EXTERNAL_VOLUME/CloudCache/OneDrive"
mkdir -p "$EXTERNAL_VOLUME/CloudCache/GoogleDrive"
mkdir -p "$EXTERNAL_VOLUME/Work"

###############################################################################
# Move ~/Library/Caches → external drive
###############################################################################

USER_CACHE="$HOME/Library/Caches"
TARGET_CACHE="$EXTERNAL_VOLUME/Caches/user/Caches"

if [[ -L "$USER_CACHE" ]]; then
  echo "✔️ ~/Library/Caches already symlinked."
else
  echo "📦 Moving ~/Library/Caches → $TARGET_CACHE…"
  mv "$USER_CACHE" "$TARGET_CACHE"
  ln -s "$TARGET_CACHE" "$USER_CACHE"
  echo "🔗 Symlink created for ~/Library/Caches."
fi

###############################################################################
# Summary
###############################################################################

echo ""
echo "✨ External offload complete."
echo "  ~/Library/Caches → $TARGET_CACHE"
echo ""
echo "NOTE: /private/var/log and /private/var/tmp were deliberately NOT moved —"
echo "relocating live system paths mid-boot on a fresh install risks breaking"
echo "logging/temp writes. Leave those on the internal SSD."
echo ""
echo "For iCloud/OneDrive/Google Drive local sync caches, point each app's"
echo "storage location setting (in its own preferences) at:"
echo "  $EXTERNAL_VOLUME/CloudCache/<service>"
echo "There is no reliable universal symlink trick for these — each client"
echo "manages its own sync folder and some refuse to run from a symlink."
