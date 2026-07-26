#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# Cloudflare Zero Trust + Tunnel Setup
# Creates tunnels for macOS (SSH) and rPi4 (Cockpit).
###############################################################################

echo "☁️ Cloudflare tunnel setup starting…"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "❌ cloudflared not installed. Install via brew.sh first."
  exit 1
fi

###############################################################################
# Authenticate cloudflared
# NOTE: this is a browser-based OAuth flow (opens Safari), NOT a token piped
# via stdin. It writes a cert to ~/.cloudflared/cert.pem. The CF_API_TOKEN
# prompt earlier in macos.sh is unused by this step — remove that prompt if
# you don't need the token elsewhere, or use it for scripted API calls only.
###############################################################################

if [[ -f "$HOME/.cloudflared/cert.pem" ]]; then
  echo "✔️ Already authenticated with Cloudflare."
else
  echo "🔐 Opening browser to log into Cloudflare…"
  cloudflared tunnel login
fi

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

MAC_TUNNEL_ID=$(cloudflared tunnel list | grep macbookair | awk '{print $1}')
RPI4_TUNNEL_ID=$(cloudflared tunnel list | grep rpi4 | awk '{print $1}')

echo "📐 macbookair tunnel ID: $MAC_TUNNEL_ID"
echo "📐 rpi4 tunnel ID: $RPI4_TUNNEL_ID"

mkdir -p "$HOME/.cloudflared"

cat > "$HOME/.cloudflared/macbookair.yml" <<EOF
tunnel: $MAC_TUNNEL_ID
credentials-file: $HOME/.cloudflared/$MAC_TUNNEL_ID.json

ingress:
  - hostname: macbookair.jraebrown.com
    service: ssh://localhost:22
  - service: http_status:404
EOF

cat > "$HOME/.cloudflared/rpi4.yml" <<EOF
tunnel: $RPI4_TUNNEL_ID
credentials-file: $HOME/.cloudflared/$RPI4_TUNNEL_ID.json

ingress:
  - hostname: rpi4.jraebrown.com
    service: http://rpi4.local:9090
  - service: http_status:404
EOF

echo "🌐 Creating DNS records…"
cloudflared tunnel route dns macbookair macbookair.jraebrown.com
cloudflared tunnel route dns rpi4 rpi4.jraebrown.com

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

launchctl load "$HOME/Library/LaunchAgents/com.jraebrown.macbookair.tunnel.plist" || true
launchctl load "$HOME/Library/LaunchAgents/com.jraebrown.rpi4.tunnel.plist" || true

echo ""
echo "✨ Cloudflare tunnels configured."
echo ""
