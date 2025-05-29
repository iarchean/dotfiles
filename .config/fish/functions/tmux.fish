function t
    if test (count $argv) -eq 0
        tmux attach -t BASE 2>/dev/null; or tmux new -s BASE
    else
        tmux attach -t $argv[1] 2>/dev/null; or tmux new -s $argv[1]
    end
end

function tl
    set -l preview_cmd 'tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}: #{window_name}#{?window_active, (active),} #{pane_current_command}" | grep "^$1:"'
    set -l session (tmux list-sessions -F "#{session_name}" 2>/dev/null | \
        fzf --height 40% \
            --reverse \
            --border rounded \
            --margin 3,3 \
            --padding 1,1 \
            --preview $preview_cmd \
            --preview-window "right:60%" \
            --color "bg+:#2d2d2d,bg:#1a1a1a,spinner:#f5e0dc,hl:#f38ba8" \
            --color "fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc" \
            --color "marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8" \
            --prompt "select session 󰚺 ")
    if test -n "$session"
        tmux attach -t $session
    end
end
