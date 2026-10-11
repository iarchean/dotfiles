function herdr --description 'Herdr: 裸调用时在当前目录打开/复用 workspace'
    # 带参数（子命令、--session、--help 等）一律原样透传
    if test (count $argv) -gt 0
        command herdr $argv
        return
    end

    set -l dir (pwd)

    # server 没跑：裸跑即可，首个 workspace 会落在当前目录
    if not command herdr status server 2>/dev/null | string match -q 'status: running'
        command herdr
        return
    end

    # 已有指向该目录的 workspace 就复用，否则按当前目录新建
    set -l ws (command herdr pane list 2>/dev/null \
        | jq -r --arg d $dir '.result.panes[] | select(.cwd == $d) | .workspace_id' \
        | head -n1)

    if test -n "$ws"
        command herdr workspace focus $ws >/dev/null
    else
        command herdr workspace create --cwd $dir --focus >/dev/null
    end

    # 已经在 herdr 的 pane 里时只切换，不再嵌套 attach
    if test "$HERDR_ENV" = 1
        return
    end

    command herdr
end
