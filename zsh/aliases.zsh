# Jonathan Rae‑Brown — aliases

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -l'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# System
alias c='clear'
alias h='history'
alias update='sudo softwareupdate -ia'
alias brewup='brew update && brew upgrade && brew cleanup'

# Networking
alias myip='curl ifconfig.me'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# Cloudflare
alias cf='cloudflared'
alias cft='cloudflared tunnel list'

# rPi shortcuts
alias rpi4='ssh rpi4.local'
alias rpi3='ssh rpi3.local'
