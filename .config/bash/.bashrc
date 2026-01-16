# Bash Configuration
# Main config file at ~/.config/bash/.bashrc

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
eval "$(starship init bash)"

# mise (runtime version manager)
eval "$(mise activate bash)"

# OrbStack
source ~/.orbstack/shell/init.bash 2>/dev/null || :

# Google Cloud SDK completion
[[ -f '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc' ]] && source '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'

# History
HISTFILE="$HOME/.bash_history"
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend
