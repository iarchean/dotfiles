if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source
# enable_transience

# set fish the default shell
# sudo bash -c 'echo $(which fish) >> /etc/shells'
# chsh -s $(which fish)

source ~/.config/fish/functions/kubernetes.fish
source ~/.config/fish/functions/tmux.fish
source ~/.config/fish/functions/gcp.fish

# # vscode
# string match -q "$TERM_PROGRAM" "vscode"
# and . (code --locate-shell-integration-path fish)

# thefuck
# eval (thefuck --alias | tr '\n' ';')

# sensitive profile (using bass to source bash format)
if test -f ~/.profile-sensitive
    bass source ~/.profile-sensitive
end

# sensitive aliases (same syntax works for fish)
if test -f ~/.aliases-sensitive
    source ~/.aliases-sensitive
end

# task
set -x TASK_X_REMOTE_TASKFILES 1

# XDG_CONFIG_HOME
set -x XDG_CONFIG_HOME "$HOME/.config"

# XDG_CACHE_HOME
set -x XDG_CACHE_HOME "$HOME/.cache"

# google cloud sdk
set -x CLOUDSDK_CONFIG "$HOME/.gcloud"
set -x GOOGLE_APPLICATION_CREDENTIALS "$CLOUDSDK_CONFIG/application_default_credentials.json"
fish_add_path /opt/homebrew/share/google-cloud-sdk/bin

# string match -q "$TERM_PROGRAM" "kiro" and . (kiro --locate-shell-integration-path fish)

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
