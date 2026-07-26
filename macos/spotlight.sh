#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# Spotlight Indexing Rules — Jonathan Rae‑Brown
# Minimal indexing: only Documents, Work, and shallow cloud folders.
# Disable indexing on CloudCache, Caches, Backup, and app bundles.
###############################################################################

echo "🔍 Applying Spotlight indexing rules…"

###############################################################################
# Enable indexing on Documents + Work
###############################################################################

sudo mdutil -i on "$HOME/Documents"
sudo mdutil -i on "/Volumes/Work"

###############################################################################
# Disable indexing on CloudCache + Caches
###############################################################################

sudo mdutil -i off "/Volumes/CloudCache"
sudo mdutil -i off "/Volumes/Caches"

###############################################################################
# Disable indexing on Backup folders
###############################################################################

if [[ -d "$HOME/Backup" ]]; then
  sudo mdutil -i off "$HOME/Backup"
fi

###############################################################################
# Disable indexing inside app bundles
###############################################################################

find /Applications -type d -name "*.app" -maxdepth 1 -exec sudo mdutil -i off "{}" \; 2>/dev/null || true

###############################################################################
# Shallow indexing for cloud storage (first 2 levels only)
###############################################################################

for cloud in "/Volumes/CloudCache/iCloud" "/Volumes/CloudCache/OneDrive" "/Volumes/CloudCache/GoogleDrive"; do
  if [[ -d "$cloud" ]]; then
    echo "📁 Configuring shallow indexing for $cloud…"
    sudo mdutil -i on "$cloud"
    find "$cloud" -mindepth 3 -maxdepth 10 -type d -exec sudo mdutil -i off "{}" \; 2>/dev/null || true
  fi
done

###############################################################################
# Summary
###############################################################################

echo ""
echo "✨ Spotlight indexing rules applied."
echo ""
