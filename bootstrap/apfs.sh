#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# External Cache/Cloud Offload Setup — quota-capped APFS volumes
# Creates (or resizes) three volumes inside the external drive's APFS
# container: Caches, CloudCache, Work. Quotas are recalculated every run
# from current container capacity, so they track your actual free space.
###############################################################################

EXTERNAL_VOLUME="/Volumes/Backup"

# Split ratio between the three volumes (Caches : CloudCache : Work).
# Override per-run, e.g.: RATIO_WORK=6 ./apfs.sh
RATIO_CACHES="${RATIO_CACHES:-1}"
RATIO_CLOUDCACHE="${RATIO_CLOUDCACHE:-2}"
RATIO_WORK="${RATIO_WORK:-4}"

# % of total container capacity left unallocated as a safety buffer.
SAFETY_MARGIN_PCT="${SAFETY_MARGIN_PCT:-10}"

echo "💾 External offload setup starting…"

if [[ ! -d "$EXTERNAL_VOLUME" ]]; then
  echo "❌ External drive not found at $EXTERNAL_VOLUME"
  echo "   Plug it in, or fix EXTERNAL_VOLUME at the top of this script."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 required (installed by brew.sh). Run that first."
  exit 1
fi

###############################################################################
# Resolve the APFS container backing the external drive
###############################################################################

CONTAINER="$(diskutil info "$EXTERNAL_VOLUME" | awk -F': +' '/APFS Container Reference/{print $2}')"

if [[ -z "$CONTAINER" ]]; then
  echo "❌ Could not resolve APFS container for $EXTERNAL_VOLUME"
  echo "   Is it actually an APFS-formatted drive?"
  exit 1
fi

echo "📦 Container: $CONTAINER"

###############################################################################
# Work out the quota budget: total capacity minus space used by volumes
# we don't manage, minus safety margin.
###############################################################################

read -r CACHES_QUOTA CLOUDCACHE_QUOTA WORK_QUOTA <<EOF
$(diskutil apfs list -plist "$CONTAINER" | python3 - "$RATIO_CACHES" "$RATIO_CLOUDCACHE" "$RATIO_WORK" "$SAFETY_MARGIN_PCT" <<'PY'
import plistlib, sys

r_caches, r_cloud, r_work, margin_pct = (float(x) for x in sys.argv[1:5])
data = plistlib.loads(sys.stdin.buffer.read())
container = data["Containers"][0]
capacity = container["CapacityCeiling"]

MANAGED = {"Caches", "CloudCache", "Work"}
used_by_others = sum(
    v.get("CapacityInUse", 0)
    for v in container["Volumes"]
    if v.get("Name") not in MANAGED
)

margin = capacity * (margin_pct / 100)
budget = capacity - used_by_others - margin

if budget <= 0:
    sys.stderr.write("Not enough free space after margin/other volumes.\n")
    sys.exit(1)

total_ratio = r_caches + r_cloud + r_work
caches_q = int(budget * r_caches / total_ratio)
cloud_q = int(budget * r_cloud / total_ratio)
work_q = int(budget * r_work / total_ratio)

print(caches_q, cloud_q, work_q)
PY
)
EOF

GB() { python3 -c "print(f'{$1/1_000_000_000:.1f}G')"; }

echo "📐 Budget this run — Caches: $(GB $CACHES_QUOTA)  CloudCache: $(GB $CLOUDCACHE_QUOTA)  Work: $(GB $WORK_QUOTA)"

###############################################################################
# Create volume if missing, else update its quota
###############################################################################

ensure_volume() {
  local name="$1" quota="$2"

  if diskutil apfs list -plist "$CONTAINER" | python3 -c "
import plistlib, sys
d = plistlib.loads(sys.stdin.buffer.read())
names = [v.get('Name') for v in d['Containers'][0]['Volumes']]
sys.exit(0 if '$name' in names else 1)
"; then
    echo "🔧 Updating quota for '$name' → $(GB $quota)"
    diskutil apfs updateVolume "$name" -quota "${quota}B"
  else
    echo "➕ Creating volume '$name' with quota $(GB $quota)"
    diskutil apfs addVolume "$CONTAINER" APFS "$name" -quota "${quota}B"
  fi
}

ensure_volume "Caches" "$CACHES_QUOTA"
ensure_volume "CloudCache" "$CLOUDCACHE_QUOTA"
ensure_volume "Work" "$WORK_QUOTA"

###############################################################################
# Prepare subdirectories on the new volumes
###############################################################################

mkdir -p "/Volumes/Caches/user"
mkdir -p "/Volumes/Caches/system"
mkdir -p "/Volumes/CloudCache/iCloud"
mkdir -p "/Volumes/CloudCache/OneDrive"
mkdir -p "/Volumes/CloudCache/GoogleDrive"

###############################################################################
# Move ~/Library/Caches → Caches volume
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
# Summary
###############################################################################

echo ""
echo "✨ External offload complete."
echo "  ~/Library/Caches → $TARGET_CACHE"
echo ""
echo "NOTE: /private/var/log and /private/var/tmp were deliberately NOT moved."
echo ""
echo "For iCloud/OneDrive/Google Drive local sync caches, point each app's"
echo "storage location setting at: /Volumes/CloudCache/<service>"
echo ""
echo "Re-run this script any time to recalculate quotas against current"
echo "free space — safe to run repeatedly (updates existing volumes)."
