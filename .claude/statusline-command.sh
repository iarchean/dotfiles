#!/usr/bin/env bash
# Claude Code status line.
#
# Doubles as the data source for the tmux AI-AGENT status bar: the
# rate_limits block is only ever handed to this script on stdin — it is
# not persisted anywhere under ~/.claude — so we snapshot the fields tmux
# needs into $XDG_RUNTIME_DIR/cc-tmux/<pane>.json on every refresh.
#
# See .config/tmux/scripts/tmux-agent-status for the consumer side.

set -u

input="$(cat)"

command -v jq >/dev/null 2>&1 || { printf 'jq missing\n'; exit 0; }

# -- export the tmux snapshot first, so a rendering error below can't cost us
#    the status bar data ------------------------------------------------------
if [ -n "${TMUX_PANE:-}" ]; then
  dir="${XDG_RUNTIME_DIR:-/tmp}/cc-tmux"
  if mkdir -p "$dir" 2>/dev/null; then
    tmp="$dir/.${TMUX_PANE}.$$"
    if printf '%s' "$input" | jq -c '{
          model:      (.model.display_name // empty),
          ctx:        (.context_window.used_percentage // empty),
          five:       (.rate_limits.five_hour.used_percentage // empty),
          five_reset: (.rate_limits.five_hour.resets_at // empty),
          seven:      (.rate_limits.seven_day.used_percentage // empty),
          cost:       (.cost.total_cost_usd // empty),
          session:    (.session_id // empty),
          ts:         (now | floor)
        }' >"$tmp" 2>/dev/null; then
      mv -f "$tmp" "$dir/${TMUX_PANE}.json" 2>/dev/null
    else
      rm -f "$tmp" 2>/dev/null
    fi
  fi
fi

# -- render ------------------------------------------------------------------
eval "$(printf '%s' "$input" | jq -r '
  @sh "model=\(.model.display_name // "?")",
  @sh "ctx=\(.context_window.used_percentage // "")",
  @sh "five=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "cost=\(.cost.total_cost_usd // "")",
  @sh "cwd=\(.workspace.current_dir // "")"
' 2>/dev/null)"

DIM='\033[2m'; RESET='\033[0m'
GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; BLUE='\033[34m'

# 10-cell bar, coloured by how full it is.
bar() {
  local pct="${1%%.*}" width=10 filled i out=''
  [ -z "$pct" ] && return
  [ "$pct" -gt 100 ] 2>/dev/null && pct=100
  filled=$(( pct * width / 100 ))
  for ((i = 0; i < width; i++)); do
    if [ "$i" -lt "$filled" ]; then out="$out▓"; else out="$out░"; fi
  done
  if   [ "$pct" -ge 85 ]; then printf '%b' "$RED$out$RESET"
  elif [ "$pct" -ge 60 ]; then printf '%b' "$YELLOW$out$RESET"
  else                         printf '%b' "$GREEN$out$RESET"
  fi
}

out=$(printf '%b' "$BLUE$model$RESET")

if [ -n "${ctx:-}" ]; then
  out="$out $(bar "$ctx") $(printf '%b' "$DIM${ctx%%.*}%$RESET")"
fi

if [ -n "${five:-}" ]; then
  out="$out $(printf '%b' "$DIM│$RESET") $(printf '%b' "${DIM}5h$RESET") ${five%%.*}%"
fi

if [ -n "${cost:-}" ]; then
  out="$out $(printf '%b' "$DIM│$RESET") $(printf '$%.2f' "$cost" 2>/dev/null || printf '')"
fi

if [ -n "${cwd:-}" ] && command -v git >/dev/null 2>&1; then
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ -n "$branch" ] && out="$out $(printf '%b' "$DIM│  $branch$RESET")"
fi

printf '%b\n' "$out"
