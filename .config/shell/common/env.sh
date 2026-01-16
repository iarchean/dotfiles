# Common environment variables for all shells
# This file is sourced by bash, zsh, and fish (via wrapper)

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"

# Editor
export EDITOR="nvim"

# Task
export TASK_X_REMOTE_TASKFILES=1

# Google Cloud SDK
export CLOUDSDK_CONFIG="$HOME/.gcloud"
export GOOGLE_APPLICATION_CREDENTIALS="$CLOUDSDK_CONFIG/application_default_credentials.json"

# Golang
export GOROOT="$(go env GOROOT 2>/dev/null)"

# Gcode
export GCODE_HOME="$HOME/gcode"
