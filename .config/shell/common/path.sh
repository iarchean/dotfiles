# Common PATH configuration for bash/zsh
# This file is sourced by bash and zsh

# Homebrew (detect architecture)
if [[ "$(uname -m)" == "arm64" ]]; then
    [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
else
    [[ -f /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
fi

# Base paths
export PATH="$PATH:/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin"

# User bin
export PATH="$PATH:$HOME/.bin"

# GNU Coreutils
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/usr/local/opt/coreutils/libexec/gnubin:$PATH"

# Golang
export PATH="$PATH:$(go env GOPATH 2>/dev/null)/bin"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Python
export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"

# Ruby
export PATH="/usr/local/opt/ruby/bin:$PATH"

# Bun
export PATH="$HOME/.bun/bin:$PATH"

# Gcode
export PATH="$PATH:$GCODE_HOME/bin"

# Google Cloud SDK
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
[[ -f '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc' ]] && source '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
[[ -f '/usr/local/share/google-cloud-sdk/path.bash.inc' ]] && source '/usr/local/share/google-cloud-sdk/path.bash.inc'
