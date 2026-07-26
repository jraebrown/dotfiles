#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# External Cache/Cloud Offload Setup
# Moves ~/Library/Caches and cloud-sync scratch space onto an external drive
# so the internal SSD doesn't fill up. Does NOT touch the internal APFS
# container — same-container volumes share physical storage and don't save
# space, which is why this uses a genuinely separate physical disk instead.
###############################################################################

EXTERNAL_VOLUME_NAME="${EXTERNAL_VOLUME_NAME:-Backup}"
EXTERNAL_VOLUME="/Volumes/$EXTERNAL_VOLUME_NAME"

echo "💾 External offload setup starting…"

if [[ ! -d "$EXTERNAL_VOLUME" ]]; then
  echo "❌ External drive not found at $EXTERNAL_VOLUME"
  echo "   Plug it in, or set EXTERNAL_VOLUME_NAME to match your drive."
  exit 1
fi

mkdir -p "$EXTERNAL_VOLUME/Caches/user"
mkdir -p "$EXTERNAL_VOLUME/Caches/system"
mkdir -p "$EXTERNAL_VOLUME/CloudCache/iCloud"
mkdir -p "$EXTERNAL_VOLUME/CloudCache/OneDrive"
mkdir -p "$EXTERNAL_VOLUME/CloudCache/GoogleDrive"
mkdir -p "$EXTERNAL_VOLUME/Work"

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

echo ""
echo "✨ External offload complete."
echo "  ~/Library/Caches → $TARGET_CACHE"
echo ""
echo "NOTE: /private/var/log and /private/var/tmp were deliberately NOT moved —"
echo "relocating live system paths mid-boot risks breaking logging/temp writes."
echo ""
echo "For iCloud/OneDrive/Google Drive local sync caches, point each app's"
echo "storage location setting at: $EXTERNAL_VOLUME/CloudCache/<service>"
