# brew
test -f /opt/homebrew/bin/brew && eval "$(/opt/homebrew/bin/brew shellenv)"
test -f /usr/local/bin/brew && eval "$(/usr/local/bin/brew shellenv)"

# brew
switch (uname -m)
    case 'arm64'
        if test -f /opt/homebrew/bin/brew
            eval (/opt/homebrew/bin/brew shellenv)
        end
    case '*'
        if test -f /usr/local/bin/brew
            eval (/usr/local/bin/brew shellenv)
        end
end

# editor

set EDITOR nvim

set PATH $PATH /usr/local/bin/ /usr/local/sbin /usr/bin /bin /usr/sbin /sbin
# ~/.bin
set PATH $PATH /Users/archean/.bin

# golang
set GOROOT $(go env GOROOT)
set PATH $PATH $(go env GOPATH)/bin

# Java
set JAVA_HOME $(/usr/libexec/java_home -v 1.8)
set PATH /usr/local/opt/openjdk/bin $PATH
set CPPFLAGS -I/usr/local/opt/openjdk/include

# GNU Coreutils
set PATH /usr/local/opt/coreutils/libexec/gnubin $PATH
set PATH /opt/homebrew/opt/coreutils/libexec/gnubin $PATH

# Ruby
set PATH /usr/local/opt/ruby/bin $PATH

# Rust
set PATH $HOME/.cargo/bin $PATH

# Python
set PATH /opt/homebrew/opt/python@3.12/libexec/bin $PATH

# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
[ -f '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc' ] && source '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc'
[ -f '/usr/local/share/google-cloud-sdk/path.fish.inc' ] && source '/usr/local/share/google-cloud-sdk/path.fish.inc'

# The next line enables shell command completion for gcloud.
# [ -f '/Users/archean/.google-cloud-sdk/completion.bash.inc' ] && bass source '/Users/archean/.google-cloud-sdk/completion.bash.inc'

# bun
set PATH ~/.bun/bin $PATH

# gocode
set GCODE_HOME "$HOME/gcode"
set PATH $PATH $GCODE_HOME/bin

# task
set -x TASK_X_REMOTE_TASKFILES 1
