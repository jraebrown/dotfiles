#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# APFS Volume Setup
# Creates CloudCache, Caches, and Work volumes with quotas.
# Moves noisy folders and creates symlinks.
###############################################################################

echo "📦 APFS volume setup starting…"

# Detect APFS container (usually disk3 on modern macOS)
APFS_CONTAINER=$(diskutil info / | awk -F': *' '/Part of Whole/ {print $2}')
echo "📐 APFS container detected: $APFS_CONTAINER"

create_volume() {
  local name="$1"
  local quota="$2"

  if diskutil apfs list | grep -q "$name"; then
    echo "✔️ APFS volume '$name' already exists."
  else
    echo "➕ Creating APFS volume '$name' with quota $quota…"
    diskutil apfs addVolume "$APFS_CONTAINER" APFS "$name" -quota "$quota"
  fi
}

###############################################################################
# Create volumes
###############################################################################

create_volume "CloudCache" "50g"
create_volume "Caches" "50g"
create_volume "Work" "50g"

###############################################################################
# Prepare directories inside volumes
###############################################################################

echo "📁 Preparing directories inside APFS volumes…"

mkdir -p /Volumes/Caches/system
mkdir -p /Volumes/Caches/user
mkdir -p /Volumes/CloudCache/iCloud
mkdir -p /Volumes/CloudCache/OneDrive
mkdir -p /Volumes/CloudCache/GoogleDrive
mkdir -p /Volumes/Work

###############################################################################
# Move ~/Library/Caches → /Volumes/Caches/user/Caches
###############################################################################

USER_CACHE="$HOME/Library/Caches"
TARGET_CACHE="/Volumes/Caches/user/Caches"

if [[ -L "$USER_CACHE" ]]; then
  echo "✔️ ~/Library/Caches already symlinked."
else
  echo "📦 Moving ~/Library/Caches → $TARGET_CACHE…"
  mv "$USER_CACHE" "$TARGET_CACHE"
  ln -s "$TARGET_CACHE" "$USER_CACHE"
  echo "🔗 Symlink created for ~/Library/Caches."
fi

###############################################################################
# Move system logs to Caches volume
###############################################################################

SYSTEM_LOG="/private/var/log"
TARGET_SYSTEM_LOG="/Volumes/Caches/system/log"

if [[ -L "$SYSTEM_LOG" ]]; then
  echo "✔️ /private/var/log already symlinked."
else
  echo "📦 Moving /private/var/log → $TARGET_SYSTEM_LOG…"
  mkdir -p "$TARGET_SYSTEM_LOG"
  mv "$SYSTEM_LOG"/* "$TARGET_SYSTEM_LOG" 2>/dev/null || true
  rm -rf "$SYSTEM_LOG"
  ln -s "$TARGET_SYSTEM_LOG" "$SYSTEM_LOG"
  echo "🔗 Symlink created for /private/var/log."
fi

###############################################################################
# Move /private/var/tmp to Caches volume
###############################################################################

SYSTEM_TMP="/private/var/tmp"
TARGET_SYSTEM_TMP="/Volumes/Caches/system/tmp"

if [[ -L "$SYSTEM_TMP" ]]; then
  echo "✔️ /private/var/tmp already symlinked."
else
  echo "📦 Moving /private/var/tmp → $TARGET_SYSTEM_TMP…"
  mkdir -p "$TARGET_SYSTEM_TMP"
  mv "$SYSTEM_TMP"/* "$TARGET_SYSTEM_TMP" 2>/dev/null || true
  rm -rf "$SYSTEM_TMP"
  ln -s "$TARGET_SYSTEM_TMP" "$SYSTEM_TMP"
  echo "🔗 Symlink created for /private/var/tmp."
fi

###############################################################################
# Summary
###############################################################################

echo ""
echo "✨ APFS setup complete."
echo "Volumes created:"
echo "  - CloudCache"
echo "  - Caches"
echo "  - Work"
echo ""
echo "Symlinks applied:"
echo "  - ~/Library/Caches → /Volumes/Caches/user/Caches"
echo "  - /private/var/log → /Volumes/Caches/system/log"
echo "  - /private/var/tmp → /Volumes/Caches/system/tmp"
echo ""
