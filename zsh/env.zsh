# Jonathan Rae‑Brown — environment variables

# Editor
export EDITOR="nano"

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# History
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000

# Locale
export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"

# Cloudflare
export CF_API_TOKEN="${CF_API_TOKEN:-}"

# Python
export PYTHONUNBUFFERED=1

# Node
export NODE_OPTIONS="--max-old-space-size=4096"

# Disable telemetry for tools that support it
export HOMEBREW_NO_ANALYTICS=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export AZURE_CORE_COLLECT_TELEMETRY=0
export GIT_TERMINAL_PROMPT=1
