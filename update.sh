#!/usr/bin/env bash
# Update claude-statusline to the latest version on origin/main.
# Usage:  bash update.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${HOME}/.claude"
TARGET_SCRIPT="${TARGET_DIR}/statusline.sh"

green() { printf '\033[32m%s\033[0m' "$*"; }
yellow() { printf '\033[33m%s\033[0m' "$*"; }
info() { printf '%s %s\n' "$(green '➜')" "$*"; }
warn() { printf '%s %s\n' "$(yellow '!')" "$*"; }

cd "$SCRIPT_DIR"

if [ ! -d ".git" ]; then
  warn "Not a git checkout — skipping git pull. Re-run install.sh manually if you want to copy a fresh script."
  exit 0
fi

OLD_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
info "Pulling latest changes..."
git pull --ff-only

NEW_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

if [ "$OLD_HEAD" = "$NEW_HEAD" ]; then
  info "Already up to date ($(git rev-parse --short HEAD))."
else
  info "Updated $(git rev-parse --short "$OLD_HEAD") → $(git rev-parse --short "$NEW_HEAD")"
fi

# Delegate to install.sh so the wrapper (Windows), settings.json command,
# and any future generated artifacts stay in sync with the script.
if [ -f "${SCRIPT_DIR}/install.sh" ]; then
  info "Re-running installer to refresh script + settings..."
  bash "${SCRIPT_DIR}/install.sh"
else
  mkdir -p "$TARGET_DIR"
  cp "${SCRIPT_DIR}/statusline.sh" "$TARGET_SCRIPT"
  chmod +x "$TARGET_SCRIPT"
  info "Refreshed $TARGET_SCRIPT"
fi

VERSION=$(cat "${SCRIPT_DIR}/VERSION" 2>/dev/null || echo "")
if [ -n "$VERSION" ]; then
  info "Now running version $(green "$VERSION")"
fi
