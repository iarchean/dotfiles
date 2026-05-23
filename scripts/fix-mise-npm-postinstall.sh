#!/usr/bin/env bash
# mise's npm backend always passes --ignore-scripts to `npm install` for
# safety, which prevents packages like @anthropic-ai/claude-code and
# opencode-ai from setting up their platform-native binaries. This script
# walks every mise-installed npm package and runs its postinstall script
# manually if one exists.
#
# Re-run after `mise install` whenever new npm tools are added or upgraded.

set -e

MISE_INSTALLS="${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs"

if [ ! -d "$MISE_INSTALLS" ]; then
  echo "No mise installs dir at $MISE_INSTALLS — nothing to do."
  exit 0
fi

ran=0
while IFS= read -r script; do
  pkg_dir="$(dirname "$script")"
  script_name="$(basename "$script")"
  rel="${pkg_dir#"$MISE_INSTALLS"/}"
  echo "→ $rel  ($script_name)"
  ( cd "$pkg_dir" && node "$script_name" ) || echo "  WARN: $script_name failed"
  ran=$((ran + 1))
done < <(find "$MISE_INSTALLS" -path '*/npm-*/lib/node_modules/*' \
           \( -name 'install.cjs' -o -name 'postinstall.mjs' -o -name 'postinstall.js' \) \
           -type f 2>/dev/null)

if [ "$ran" -eq 0 ]; then
  echo "No mise-installed npm packages with postinstall scripts found."
fi
