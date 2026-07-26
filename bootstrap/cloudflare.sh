#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# Cloudflare Zero Trust + Tunnel Setup
# Creates tunnels for macOS (SSH) and rPi4 (Cockpit).
# Uses Cloudflare API token provided by user at bootstrap start.
###############################################################################

echo "☁️ Cloudflare tunnel setup starting…"

###############################################################################
# Ensure cloudflared is installed
###############################################################################

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "❌ cloudflared not installed. Install via brew.sh first."
  exit 1
fi

###############################################################################
# Authenticate cloudflared
###############################################################################

echo "🔐 Logging into Cloudflare…"
echo "$CF_API_TOKEN" | cloudflared login || {
  echo "❌ Cloudflare login failed."
  exit 1
}

###############################################################################
# Create tunnels if missing
###############################################################################

create_tunnel() {
  local name="$1"

  if cloudflared tunnel list | grep -q "$name"; then
    echo "✔️ Tunnel '$name' already exists."
  else
    echo "➕ Creating tunnel '$name'…"
    cloudflared tunnel create "$name"
  fi
}

create_tunnel "macbookair"
create_tunnel "rpi4"

###############################################################################
# Get tunnel IDs
###############################################################################

MAC_TUNNEL_ID=$(cloudflared tunnel list | grep macbookair | awk '{print $1}')
RPI4_TUNNEL_ID=$(cloudflared tunnel list | grep rpi4 | awk '{print $1}')

echo "📐 macbookair tunnel ID: $MAC_TUNNEL_ID"
echo "📐 rpi4 tunnel ID: $RPI4_TUNNEL_ID"

###############################################################################
# Write tunnel configs
###############################################################################

mkdir -p "$HOME/.cloudflared"

echo "📝 Writing macbookair tunnel config…"

cat > "$HOME/.cloudflared/macbookair.yml" <<EOF
tunnel: $MAC_TUNNEL_ID
credentials-file: $HOME/.cloudflared/$MAC_TUNNEL_ID.json

ingress:
  - hostname: macbookair.jraebrown.com
    service: ssh://localhost:22
  - service: http_status:404
EOF

echo "📝 Writing rpi4 tunnel config…"

cat > "$HOME/.cloudflared/rpi4.yml" <<EOF
tunnel: $RPI4_TUNNEL_ID
credentials-file: $HOME/.cloudflared/$RPI4_TUNNEL_ID.json

ingress:
  - hostname: rpi4.jraebrown.com
    service: http://rpi4.local:9090
  - service: http_status:404
EOF

###############################################################################
# Create DNS records
###############################################################################

echo "🌐 Creating DNS records…"

cloudflared tunnel route dns macbookair macbookair.jraebrown.com
cloudflared tunnel route dns rpi4 rpi4.jraebrown.com

###############################################################################
# Create launchd services
###############################################################################

echo "⚙️ Creating launchd services…"

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$HOME/Library/LaunchAgents/com.jraebrown.macbookair.tunnel.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.jraebrown.macbookair.tunnel</string>
  <key>ProgramArguments</key>
  <array>
    <string>/opt/homebrew/bin/cloudflared</string>
    <string>tunnel</string>
    <string>--config</string>
    <string>$HOME/.cloudflared/macbookair.yml</string>
    <string>run</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF

cat > "$HOME/Library/LaunchAgents/com.jraebrown.rpi4.tunnel.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.jraebrown.rpi4.tunnel</string>
  <key>ProgramArguments</key>
  <array>
    <string>/opt/homebrew/bin/cloudflared</string>
    <string>tunnel</string>
    <string>--config</string>
    <string>$HOME/.cloudflared/rpi4.yml</string>
    <string>run</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF

###############################################################################
# Load launchd services
###############################################################################

launchctl load "$HOME/Library/LaunchAgents/com.jraebrown.macbookair.tunnel.plist" || true
launchctl load "$HOME/Library/LaunchAgents/com.jraebrown.rpi4.tunnel.plist" || true

###############################################################################
# Summary
###############################################################################

echo ""
echo "✨ Cloudflare tunnels configured:"
echo "  - macbookair.jraebrown.com → SSH → localhost:22"
echo "  - rpi4.jraebrown.com → Cockpit → rpi4.local:9090"
echo ""
echo "Launchd services installed and loaded."
echo "Cloudflare Zero Trust is active."
echo ""
