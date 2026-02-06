#!/bin/bash
# Script to execute kubectl commands in a new tmux panel on the right side
# Usage: tmux-exec.sh [--keep-open] <command> [args...]
#   --keep-open: Keep the pane open after command completion by starting a shell

# Check if we're inside a tmux session
if [ -z "$TMUX" ]; then
    # Not in tmux, execute directly (remove --keep-open if present)
    if [ "$1" = "--keep-open" ]; then
        shift
    fi
    exec "$@"
    exit $?
fi

# Check if --keep-open flag is present (can be first or last argument)
KEEP_OPEN=false
ARGS=()

# Check first argument
if [ "$1" = "--keep-open" ]; then
    KEEP_OPEN=true
    shift
fi

# Process remaining arguments
while [ $# -gt 0 ]; do
    if [ "$1" = "--keep-open" ]; then
        # Found --keep-open, skip it and set flag
        KEEP_OPEN=true
        shift
    else
        # Normal argument, add to array
        ARGS+=("$1")
        shift
    fi
done

if [ "$KEEP_OPEN" = true ]; then
    # Command should execute and then start shell to keep pane open
    USER_SHELL="${SHELL:-/bin/bash}"
    # Build command string with proper escaping
    CMD_ESCAPED=$(printf '%q ' "${ARGS[@]}")
    # Execute command and then start shell in the new pane
    tmux split-window -h -l 75% "bash -c '$CMD_ESCAPED; exec $USER_SHELL'"
else
    # Normal command execution
    tmux split-window -h -l 75% "${ARGS[@]}"
fi
