# ZSH Configuration
# Main config file at ~/.config/zsh/.zshrc

# Load shared environment
source "$HOME/.config/shell/common/env.sh"

# Load shared PATH
source "$HOME/.config/shell/common/path.sh"

# Load shared aliases
source "$HOME/.config/shell/common/aliases.sh"

# Load sensitive profile if exists (universal format)
[[ -f ~/.profile-sensitive ]] && source ~/.profile-sensitive
[[ -f ~/.aliases-sensitive ]] && source ~/.aliases-sensitive

# Starship prompt
eval "$(starship init zsh)"

# mise (runtime version manager)
eval "$(mise activate zsh)"

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Google Cloud SDK completion
[[ -f '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc' ]] && source '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
