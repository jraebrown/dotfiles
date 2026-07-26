#!/usr/bin/env bash
# Run from inside ~/dotfiles. Fixes:
#  1. /Volumes/Work + /Volumes/CloudCache -> /Volumes/Backup/Work + /Volumes/Backup/CloudCache
#  2. brew.sh: install Homebrew + set PATH on Intel too
#  3. mount-rpi / brew-sync: usage message no longer eaten by `set -u`
set -euo pipefail

sed -i.bak \
  -e 's#/Volumes/Work#/Volumes/Backup/Work#g' \
  -e 's#/Volumes/CloudCache#/Volumes/Backup/CloudCache#g' \
  bootstrap/defaults.sh macos/spotlight.sh

python3 - "bootstrap/brew.sh" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
old = '''else
  echo "⚠️ Intel Mac detected — adjust Homebrew paths manually."
fi'''
new = '''else
  if [[ ! -d "/usr/local/Homebrew" ]]; then
    echo "➕ Installing Homebrew for Intel…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/usr/local/bin/brew shellenv)"
fi'''
if old not in s:
    print("WARN: brew.sh pattern not found, skipping"); sys.exit(0)
open(p, 'w').write(s.replace(old, new))
PY

for f in scripts/bin/mount-rpi scripts/bin/brew-sync; do
  sed -i.bak 's/^TARGET="\$1"$/if [[ $# -lt 1 ]]; then\n  echo "Usage: mount-rpi <rpi4|rpi3>"\n  exit 1\nfi\nTARGET="$1"/' "$f" 2>/dev/null || true
done
# brew-sync needs its own usage guard since its arg check differs
python3 - "scripts/bin/brew-sync" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = 'BUNDLE="$HOME/dotfiles/Brewfile"\n\ncase "$1" in'
new = 'BUNDLE="$HOME/dotfiles/Brewfile"\n\nif [[ $# -lt 1 ]]; then\n  echo "Usage: brew-sync <export|import>"\n  exit 1\nfi\n\ncase "$1" in'
if old in s:
    open(p, 'w').write(s.replace(old, new))
PY

rm -f bootstrap/*.bak macos/*.bak scripts/bin/*.bak
echo "✨ Patched. Review with: git diff"
echo "Still manual: delete/update populate.sh, remove empty bootstrap/linux.sh, dedupe scripts/bin/verify(.zsh)"
