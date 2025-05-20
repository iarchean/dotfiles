if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source
# enable_transience

# set fish the default shell
# sudo bash -c 'echo $(which fish) >> /etc/shells'
# chsh -s $(which fish)

source ~/.config/fish/functions/kubernetes.fish

# vscode
string match -q "$TERM_PROGRAM" "vscode"
and . (code --locate-shell-integration-path fish)

# thefuck
# eval (thefuck --alias | tr '\n' ';')

# sensitive profile
if test -f ~/.profile-sensitive
    source ~/.profile-sensitive
end

# task
set -x TASK_X_REMOTE_TASKFILES 1

# XDG_CONFIG_HOME
set -x XDG_CONFIG_HOME "$HOME/.config"

# XDG_CACHE_HOME
set -x XDG_CACHE_HOME "$HOME/.cache"
