# Jonathan Rae‑Brown — macOS zsh config

# zsh4humans v5 bootstrap loader (the installer does NOT create a static
# zsh4humans.zsh file to source — it manages itself via ~/.cache/z4h).
# This is the official bootstrap snippet.
if [ -r "${XDG_CACHE_HOME:-$HOME/.cache}/z4h/z4h.zsh" ]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/z4h/z4h.zsh"
fi

# Load aliases
source "$HOME/.config/zsh/aliases.zsh"

# Load environment variables
source "$HOME/.config/zsh/env.zsh"

# fzf keybindings
if [[ -f "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" ]]; then
  source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
fi

# fzf completion
if [[ -f "/opt/homebrew/opt/fzf/shell/completion.zsh" ]]; then
  source "/opt/homebrew/opt/fzf/shell/completion.zsh"
fi

# Prompt override (macOS)
export PROMPT="%F{cyan}%n@MacBookAir%f %F{yellow}%~%f %# "
