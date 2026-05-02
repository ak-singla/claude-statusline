#!/usr/bin/env bash
# Uninstall claude-statusline.
# Removes the statusLine block from settings.json and deletes the script.
# Leaves the cloned repo at its location — delete manually if desired.
# Usage:  bash uninstall.sh

set -euo pipefail

TARGET_DIR="${HOME}/.claude"
TARGET_SCRIPT="${TARGET_DIR}/statusline.sh"
TARGET_WRAPPER="${TARGET_DIR}/statusline.cmd"
SETTINGS="${TARGET_DIR}/settings.json"

green() { printf '\033[32m%s\033[0m' "$*"; }
yellow() { printf '\033[33m%s\033[0m' "$*"; }
info() { printf '%s %s\n' "$(green '➜')" "$*"; }
warn() { printf '%s %s\n' "$(yellow '!')" "$*"; }

if [ -f "$SETTINGS" ]; then
  if command -v jq >/dev/null 2>&1; then
    cp "$SETTINGS" "${SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"
    jq 'del(.statusLine)' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
    info "Removed statusLine block from $SETTINGS"
  else
    warn "jq not available — please remove the .statusLine key from $SETTINGS manually."
  fi
fi

if [ -f "$TARGET_SCRIPT" ]; then
  rm "$TARGET_SCRIPT"
  info "Deleted $TARGET_SCRIPT"
fi

if [ -f "$TARGET_WRAPPER" ]; then
  rm "$TARGET_WRAPPER"
  info "Deleted $TARGET_WRAPPER"
fi

info "$(green 'Uninstalled.') The repo clone is still on disk — remove it with: rm -rf $(cd "$(dirname "$0")" && pwd)"
