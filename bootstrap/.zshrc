# Jonathan Rae‑Brown — macOS zsh config
# Loads zsh4humans, aliases, environment, and fzf.

# Load zsh4humans
source "$HOME/.zsh4humans/zsh4humans.zsh"

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
