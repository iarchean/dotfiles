#!/usr/bin/env bash
window_title_render() {
  local pane_name=${1:-"fish"}
  declare -A icons=(
    [ps]=""
    [top]=""
    [htop]=""
    [vim]=""
    [nvim]=""
    [k9s]=""
    [python]=""
    [python3]=""
    [node]=""
  )
  local title="#W"
  if [[ "$pane_name" =~ ^(ssh|mosh)$ ]]; then
    title=" #{hostname_ssh}"
  elif [[ -n "${icons[$pane_name]}" ]]; then
    title="${icons[$pane_name]} #W"
  fi
  echo -n "$title"
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  window_title_render "$@"
fi