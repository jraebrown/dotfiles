#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# macOS Minimal Defaults — Jonathan Rae‑Brown
# Fast UI, minimal logging, no telemetry, no Siri, no iCloud auto-save,
# reduced indexing, no .DS_Store on network volumes, hardened firewall.
###############################################################################

echo "⚙️ Applying macOS minimal defaults…"

###############################################################################
# iCloud / Documents
###############################################################################

defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

###############################################################################
# Disable Time Machine
# 'tmutil disablelocal' was removed in macOS High Sierra (2017) with no
# direct replacement — there is no way to disable ONLY local snapshots
# anymore. This disables Time Machine entirely instead.
###############################################################################

sudo tmutil disable

###############################################################################
# Disable Siri + Assistant
###############################################################################

defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri SiriAudioTriggerEnabled -bool false

###############################################################################
# UI performance tweaks
###############################################################################

defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1

###############################################################################
# Prevent .DS_Store on network + USB volumes
###############################################################################

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

###############################################################################
# Enable text selection in Quick Look
###############################################################################

defaults write com.apple.finder QLEnableTextSelection -bool true

###############################################################################
# Disable quarantine prompts
###############################################################################

defaults write com.apple.LaunchServices LSQuarantine -bool false

###############################################################################
# Security hardening
###############################################################################

# NOTE: since macOS Sequoia, this no longer fully disables Gatekeeper via CLI —
# it only reveals the "Anywhere" option in System Settings, which still needs
# manual confirmation there. Made non-fatal so it doesn't block the rest of
# this script if the command's behavior has changed further on macOS 27.
sudo spctl --master-disable || true
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

###############################################################################
# Networking tweaks
###############################################################################

sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.wifi.skipAutoJoin -bool true
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

###############################################################################
# Spotlight indexing rules
###############################################################################

echo "🔍 Configuring Spotlight indexing…"

# Enable indexing on Documents + Work
sudo mdutil -i on "$HOME/Documents"
sudo mdutil -i on "/Volumes/Backup/Work"

# Disable indexing on CloudCache + Caches
sudo mdutil -i off "/Volumes/Backup/CloudCache"
sudo mdutil -i off "/Volumes/Backup/Caches"

# Disable indexing on Backup folders
sudo mdutil -i off "$HOME/Backup" 2>/dev/null || true

###############################################################################
# Summary
###############################################################################

echo ""
echo "✨ macOS defaults applied."
echo ""
