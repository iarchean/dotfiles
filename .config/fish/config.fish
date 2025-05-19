if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source
# enable_transience

# set fish the default shell
# sudo bash -c 'echo $(which fish) >> /etc/shells'
# chsh -s $(which fish)


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

source ~/.config/fish/functions/kubernetes.fish

# vscode
string match -q "$TERM_PROGRAM" "vscode"
and . (code --locate-shell-integration-path fish)

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# thefuck
# eval (thefuck --alias | tr '\n' ';')

# sensitive profile
if test -f ~/.profile-sensitive
    source ~/.profile-sensitive
end
