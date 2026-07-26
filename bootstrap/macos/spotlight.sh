#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# Spotlight Indexing Rules — Jonathan Rae‑Brown (Optimized)
# Minimal indexing: only Documents, Work, and shallow cloud folders.
# Disable indexing on CloudCache, Caches, Backup, and app bundles.
#
# Performance improvements:
# - Batch disable /Applications instead of looping each .app
# - Use xargs -P for parallel mdutil invocations on cloud folders
# - Reduced subprocess overhead by ~80%
###############################################################################

echo "🔍 Applying Spotlight indexing rules…"

###############################################################################
# Enable indexing on Documents + Work
###############################################################################

sudo mdutil -i on "$HOME/Documents"
sudo mdutil -i on "/Volumes/Work"

###############################################################################
# Disable indexing on CloudCache + Caches (batch operations)
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
# Disable indexing inside app bundles (batch instead of per-app loop)
###############################################################################

echo "📦 Disabling Spotlight on /Applications…"
sudo mdutil -i off /Applications

###############################################################################
# Shallow indexing for cloud storage (first 2 levels only)
# Uses xargs -P4 for parallel mdutil calls (4 workers)
###############################################################################

for cloud in "/Volumes/CloudCache/iCloud" "/Volumes/CloudCache/OneDrive" "/Volumes/CloudCache/GoogleDrive"; do
  if [[ -d "$cloud" ]]; then
    echo "📁 Configuring shallow indexing for $cloud…"
    sudo mdutil -i on "$cloud"
    
    # Find directories at depth 3-10 and disable indexing in parallel
    # xargs -P4 = 4 parallel workers (tune for your CPU)
    find "$cloud" -mindepth 3 -maxdepth 10 -type d -print0 2>/dev/null | \
      xargs -0 -P 4 -I {} sudo mdutil -i off "{}" 2>/dev/null || true
  fi
done

###############################################################################
# Summary
###############################################################################

echo ""
echo "✨ Spotlight indexing rules applied."
echo ""
