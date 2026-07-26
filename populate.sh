#!/usr/bin/env zsh
set -euo pipefail

# ============================================================================
# populate.sh — Jonathan Rae‑Brown
# Writes all dotfiles into ~/dotfiles
# Split into multiple parts (Option A)
# ============================================================================

write() {
  local path="$1"
  local content="$2"
  mkdir -p "$(dirname "$path")"
  printf "%s\n" "$content" > "$path"
  echo "✔️ Wrote $path"
}

# ============================================================================
# FILE 1 — bootstrap/macos.sh
# ============================================================================
write ~/dotfiles/bootstrap/macos.sh << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

echo "🍎 macOS bootstrap starting…"

# Install Rosetta
/usr/sbin/softwareupdate --install-rosetta --agree-to-license || true

# Install Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "🍺 Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install core packages
brew install \
  git \
  fzf \
  nano \
  cloudflared \
  zsh \
  tmux \
  jq \
  gh

echo "✨ macOS bootstrap complete."
EOF

# ============================================================================
# FILE 2 — bootstrap/apfs.sh
# ============================================================================
write ~/dotfiles/bootstrap/apfs.sh << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

echo "📦 Setting up APFS volumes…"

sudo diskutil apfs addVolume disk3 APFS CloudCache -role B
sudo diskutil apfs addVolume disk3 APFS Work -role B
sudo diskutil apfs addVolume disk3 APFS Caches -role B

mkdir -p /Volumes/CloudCache
mkdir -p /Volumes/Work
mkdir -p /Volumes/Caches

echo "✨ APFS volumes created."
EOF

# ============================================================================
# FILE 3 — bootstrap/brew.sh
# ============================================================================
write ~/dotfiles/bootstrap/brew.sh << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

echo "🍺 Syncing Homebrew packages…"

brew update
brew upgrade
brew cleanup

echo "✨ Brew sync complete."
EOF

# ============================================================================
# FILE 4 — bootstrap/ssh.sh
# ============================================================================
write ~/dotfiles/bootstrap/ssh.sh << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

echo "🔐 SSH setup starting…"

KEY="$HOME/.ssh/id_ed25519"
PUB="$HOME/.ssh/id_ed25519.pub"

if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY" -N ""
fi

eval "$(ssh-agent -s)"
ssh-add "$KEY"

git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

gh auth login

if ! gh ssh-key list | grep -q "$(cat "$PUB")"; then
  gh ssh-key add "$PUB" --title "MacBookAir"
fi

mkdir -p "$HOME/.ssh"
cp "$HOME/dotfiles/ssh/config" "$HOME/.ssh/config"

chmod 600 "$HOME/.ssh/config"
chmod 600 "$KEY"
chmod 644 "$PUB"

echo "✨ SSH setup complete."
EOF

# ============================================================================
# FILE 5 — bootstrap/cloudflare.sh
# ============================================================================
write ~/dotfiles/bootstrap/cloudflare.sh << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

echo "☁️ Cloudflare tunnel setup starting…"

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "❌ cloudflared not installed."
  exit 1
fi

echo "$CF_API_TOKEN" | cloudflared login

create_tunnel() {
  local name="$1"
  if ! cloudflared tunnel list | grep -q "$name"; then
    cloudflared tunnel create "$name"
  fi
}

create_tunnel "macbookair"
create_tunnel "rpi4"

MAC_TUNNEL_ID=$(cloudflared tunnel list | grep macbookair | awk '{print $1}')
RPI4_TUNNEL_ID=$(cloudflared tunnel list | grep rpi4 | awk '{print $1}')

mkdir -p "$HOME/.cloudflared"

cat > "$HOME/.cloudflared/macbookair.yml" <<EOF2
tunnel: $MAC_TUNNEL_ID
credentials-file: $HOME/.cloudflared/$MAC_TUNNEL_ID.json
ingress:
  - hostname: macbookair.jraebrown.com
    service: ssh://localhost:22
  - service: http_status:404
EOF2

cat > "$HOME/.cloudflared/rpi4.yml" <<EOF2
tunnel: $RPI4_TUNNEL_ID
credentials-file: $HOME/.cloudflared/$RPI4_TUNNEL_ID.json
ingress:
  - hostname: rpi4.jraebrown.com
    service: http://rpi4.local:9090
  - service: http_status:404
EOF2

cloudflared tunnel route dns macbookair macbookair.jraebrown.com
cloudflared tunnel route dns rpi4 rpi4.jraebrown.com

echo "✨ Cloudflare tunnels configured."
EOF

# ============================================================================
# FILE 6 — bootstrap/dotfiles.sh
# ============================================================================
write ~/dotfiles/bootstrap/dotfiles.sh << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

echo "🔗 Linking dotfiles…"

DOTFILES="$HOME/dotfiles"

link() {
  local src="$DOTFILES/$1"
  local dest="$HOME/$2"
  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
}

link "zsh/.zshrc" ".zshrc"
link "zsh/zsh4humans.conf" ".config/zsh/zsh4humans.conf"
link "zsh/aliases.zsh" ".config/zsh/aliases.zsh"
link "zsh/env.zsh" ".config/zsh/env.zsh"

link "git/.gitconfig" ".gitconfig"
link "git/.gitignore_global" ".gitignore_global"

link "ssh/config" ".ssh/config"

link "macos/spotlight.sh" ".config/macos/spotlight.sh"
link "linux/debian.sh" ".config/linux/debian.sh"

echo "✨ Dotfiles linked."
EOF
# ============================================================================
# FILE 7 — bootstrap/defaults.sh
# ============================================================================
write ~/dotfiles/bootstrap/defaults.sh << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

echo "⚙️ Applying macOS minimal defaults…"

defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
sudo tmutil disablelocal

defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri SiriAudioTriggerEnabled -bool false

defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

defaults write com.apple.finder QLEnableTextSelection -bool true
defaults write com.apple.LaunchServices LSQuarantine -bool false

sudo spctl --master-disable
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.wifi.skipAutoJoin -bool true
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

sudo mdutil -i on "$HOME/Documents"
sudo mdutil -i on "/Volumes/Work"

sudo mdutil -i off "/Volumes/CloudCache"
sudo mdutil -i off "/Volumes/Caches"

sudo mdutil -i off "$HOME/Backup" 2>/dev/null || true

echo "✨ macOS defaults applied."
EOF

# ============================================================================
# FILE 8 — zsh/.zshrc
# ============================================================================
write ~/dotfiles/zsh/.zshrc << 'EOF'
source "$HOME/.zsh4humans/zsh4humans.zsh"
source "$HOME/.config/zsh/aliases.zsh"
source "$HOME/.config/zsh/env.zsh"

if [[ -f "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" ]]; then
  source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
fi

if [[ -f "/opt/homebrew/opt/fzf/shell/completion.zsh" ]]; then
  source "/opt/homebrew/opt/fzf/shell/completion.zsh"
fi

export PROMPT="%F{cyan}%n@MacBookAir%f %F{yellow}%~%f %# "
EOF

# ============================================================================
# FILE 9 — zsh/zsh4humans.conf
# ============================================================================
write ~/dotfiles/zsh/zsh4humans.conf << 'EOF'
z4h load autosuggestions
z4h load syntax-highlighting
z4h load fzf

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

autoload -Uz compinit
compinit

bindkey -e

export EDITOR="nano"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"
EOF

# ============================================================================
# FILE 10 — zsh/aliases.zsh
# ============================================================================
write ~/dotfiles/zsh/aliases.zsh << 'EOF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -l'

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

alias c='clear'
alias h='history'
alias update='sudo softwareupdate -ia'
alias brewup='brew update && brew upgrade && brew cleanup'

alias myip='curl ifconfig.me'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

alias cf='cloudflared'
alias cft='cloudflared tunnel list'

alias rpi4='ssh rpi4.local'
alias rpi3='ssh rpi3.local'
EOF

# ============================================================================
# FILE 11 — zsh/env.zsh
# ============================================================================
write ~/dotfiles/zsh/env.zsh << 'EOF'
export EDITOR="nano"

export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000

export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"

export CF_API_TOKEN="${CF_API_TOKEN:-}"

export PYTHONUNBUFFERED=1
export NODE_OPTIONS="--max-old-space-size=4096"

export HOMEBREW_NO_ANALYTICS=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export AZURE_CORE_COLLECT_TELEMETRY=0
export GIT_TERMINAL_PROMPT=1
EOF

# ============================================================================
# FILE 12 — git/.gitconfig
# ============================================================================
write ~/dotfiles/git/.gitconfig << 'EOF'
[user]
    name = Jonathan Rae-Brown
    email = me@jraebrown.com

[core]
    editor = nano
    excludesfile = ~/.gitignore_global
    autocrlf = input

[color]
    ui = auto

[alias]
    st = status
    co = checkout
    br = branch
    cm = commit
    lg = log --oneline --graph --decorate

[push]
    default = current

[pull]
    rebase = false

[credential]
    helper = osxkeychain

[init]
    defaultBranch = main
EOF
# ============================================================================
# FILE 13 — git/.gitignore_global
# ============================================================================
write ~/dotfiles/git/.gitignore_global << 'EOF'
.DS_Store
.AppleDouble
.LSOverride

._*

.Spotlight-V100
.Trashes

*.log

__pycache__/
*.pyc
*.pyo
*.pyd
*.pdb

node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

venv/
.env/
.envrc

*.swp
*.swo

Icon?
ehthumbs.db
Thumbs.db

*.icloud
*.tmp
*.part
EOF

# ============================================================================
# FILE 14 — ssh/config
# ============================================================================
write ~/dotfiles/ssh/config << 'EOF'
Host macbookair.local
  HostName macbookair.local
  User jonathan
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 30
  ServerAliveCountMax 5

Host macbookair.jraebrown.com
  ProxyCommand cloudflared access ssh --hostname %h
  User jonathan
  IdentityFile ~/.ssh/id_ed25519

Host rpi4.local
  HostName rpi4.local
  User pi
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 30
  ServerAliveCountMax 5

Host rpi3.local
  HostName rpi3.local
  User pi
  IdentityFile ~/.ssh/id_ed25519
  ServerAliveInterval 30
  ServerAliveCountMax 5
EOF

# ============================================================================
# FILE 15 — macos/spotlight.sh
# ============================================================================
write ~/dotfiles/macos/spotlight.sh << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

echo "🔍 Applying Spotlight indexing rules…"

sudo mdutil -i on "$HOME/Documents"
sudo mdutil -i on "/Volumes/Work"

sudo mdutil -i off "/Volumes/CloudCache"
sudo mdutil -i off "/Volumes/Caches"

if [[ -d "$HOME/Backup" ]]; then
  sudo mdutil -i off "$HOME/Backup"
fi

find /Applications -type d -name "*.app" -maxdepth 1 -exec sudo mdutil -i off "{}" \; 2>/dev/null || true

for cloud in "/Volumes/CloudCache/iCloud" "/Volumes/CloudCache/OneDrive" "/Volumes/CloudCache/GoogleDrive"; do
  if [[ -d "$cloud" ]]; then
    sudo mdutil -i on "$cloud"
    find "$cloud" -mindepth 3 -maxdepth 10 -type d -exec sudo mdutil -i off "{}" \; 2>/dev/null || true
  fi
done

echo "✨ Spotlight indexing rules applied."
EOF

# ============================================================================
# FILE 16 — macos/launchd/mount-rpi4.plist
# ============================================================================
write ~/dotfiles/macos/launchd/mount-rpi4.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.jraebrown.mount-rpi4</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>/Users/jonathan/.local/bin/mount-rpi</string>
    <string>rpi4</string>
  </array>

  <key>RunAtLoad</key>
  <true/>

  <key>StartInterval</key>
  <integer>60</integer>

  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF

# ============================================================================
# FILE 17 — macos/launchd/mount-rpi3.plist
# ============================================================================
write ~/dotfiles/macos/launchd/mount-rpi3.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.jraebrown.mount-rpi3</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>/Users/jonathan/.local/bin/mount-rpi</string>
    <string>rpi3</string>
  </array>

  <key>RunAtLoad</key>
  <true/>

  <key>StartInterval</key>
  <integer>60</integer>

  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF

# ============================================================================
# FILE 18 — linux/debian.sh
# ============================================================================
write ~/dotfiles/linux/debian.sh << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

echo "🐧 Debian bootstrap starting…"

sudo apt update
sudo apt upgrade -y

sudo apt install -y \
  zsh \
  git \
  fzf \
  nano \
  curl \
  wget \
  cockpit \
  tmux

if [[ "$SHELL" != "/usr/bin/zsh" ]]; then
  chsh -s /usr/bin/zsh
fi

DOTFILES="$HOME/dotfiles"

link() {
  local src="$DOTFILES/$1"
  local dest="$HOME/$2"
  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
}

link "zsh/.zshrc" ".zshrc"
link "zsh/aliases.zsh" ".config/zsh/aliases.zsh"
link "zsh/env.zsh" ".config/zsh/env.zsh"
link "linux/debian.sh" ".config/linux/debian.sh"

sudo systemctl enable cockpit
sudo systemctl start cockpit

echo "✨ Debian bootstrap complete."
EOF
# ============================================================================
# FILE 19 — cloudflare/tunnel-macbookair.yml
# ============================================================================
write ~/dotfiles/cloudflare/tunnel-macbookair.yml << 'EOF'
tunnel: macbookair
credentials-file: /Users/jonathan/.cloudflared/macbookair.json

ingress:
  - hostname: macbookair.jraebrown.com
    service: ssh://localhost:22
  - service: http_status:404
EOF

# ============================================================================
# FILE 20 — cloudflare/tunnel-rpi4.yml
# ============================================================================
write ~/dotfiles/cloudflare/tunnel-rpi4.yml << 'EOF'
tunnel: rpi4
credentials-file: /Users/jonathan/.cloudflared/rpi4.json

ingress:
  - hostname: rpi4.jraebrown.com
    service: http://rpi4.local:9090
  - service: http_status:404
EOF

# ============================================================================
# FILE 21 — scripts/bin/link-dotfiles
# ============================================================================
write ~/dotfiles/scripts/bin/link-dotfiles << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

DOTFILES="$HOME/dotfiles"

link() {
  local src="$DOTFILES/$1"
  local dest="$HOME/$2"
  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  echo "✔️ Linked $src → $dest"
}

echo "🔗 Relinking dotfiles…"

link "zsh/.zshrc" ".zshrc"
link "zsh/zsh4humans.conf" ".config/zsh/zsh4humans.conf"
link "zsh/aliases.zsh" ".config/zsh/aliases.zsh"
link "zsh/env.zsh" ".config/zsh/env.zsh"

link "git/.gitconfig" ".gitconfig"
link "git/.gitignore_global" ".gitignore_global"

link "ssh/config" ".ssh/config"

link "macos/spotlight.sh" ".config/macos/spotlight.sh"
link "linux/debian.sh" ".config/linux/debian.sh"

echo "✨ Dotfiles re-linked."
EOF

# ============================================================================
# FILE 22 — scripts/bin/mount-rpi
# ============================================================================
write ~/dotfiles/scripts/bin/mount-rpi << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

TARGET="$1"

if [[ -z "$TARGET" ]]; then
  echo "Usage: mount-rpi <rpi4|rpi3>"
  exit 1
fi

MOUNTPOINT="/Volumes/Work/$TARGET"
HOST="$TARGET.local"
SHARE="work"

mkdir -p "$MOUNTPOINT"

echo "📡 Attempting mount of $HOST:$SHARE → $MOUNTPOINT"

if mount | grep -q "$MOUNTPOINT"; then
  echo "✔️ Already mounted."
  exit 0
fi

mount_smbfs "//pi:@$HOST/$SHARE" "$MOUNTPOINT" 2>/dev/null || {
  echo "⚠️ Mount failed or host unreachable."
  exit 1
}

echo "✨ Mounted $TARGET successfully."
EOF

# ============================================================================
# FILE 23 — scripts/bin/update-system
# ============================================================================
write ~/dotfiles/scripts/bin/update-system << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

OS="$(uname -s)"

echo "🔧 Updating system ($OS)…"

if [[ "$OS" == "Darwin" ]]; then
  sudo softwareupdate -ia
  brew update
  brew upgrade
  brew cleanup

elif [[ "$OS" == "Linux" ]]; then
  sudo apt update
  sudo apt upgrade -y
  sudo apt autoremove -y
fi

echo "✨ System updated."
EOF

# ============================================================================
# FILE 24 — scripts/bin/brew-sync
# ============================================================================
write ~/dotfiles/scripts/bin/brew-sync << 'EOF'
#!/usr/bin/env zsh
set -euo pipefail

BUNDLE="$HOME/dotfiles/Brewfile"

case "$1" in
  export)
    brew bundle dump --file="$BUNDLE" --force
    echo "✨ Brewfile exported."
    ;;

  import)
    brew bundle install --file="$BUNDLE"
    echo "✨ Brewfile imported."
    ;;

  *)
    echo "Usage: brew-sync <export|import>"
    exit 1
    ;;
esac
EOF

# ============================================================================
# DONE
# ============================================================================
echo ""
echo "🎉 All dotfiles written successfully."
echo "You can now run: git init && git add . && git commit -m 'Initial dotfiles'"
echo ""
