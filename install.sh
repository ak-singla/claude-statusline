#!/usr/bin/env bash
# Installer for claude-statusline
# Usage:  bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_SCRIPT="${SCRIPT_DIR}/statusline.sh"
TARGET_DIR="${HOME}/.claude"
TARGET_SCRIPT="${TARGET_DIR}/statusline.sh"
SETTINGS="${TARGET_DIR}/settings.json"

# ── Pretty output helpers ─────────────────────────────────
green() { printf '\033[32m%s\033[0m' "$*"; }
yellow() { printf '\033[33m%s\033[0m' "$*"; }
red() { printf '\033[31m%s\033[0m' "$*"; }
info() { printf '%s %s\n' "$(green '➜')" "$*"; }
warn() { printf '%s %s\n' "$(yellow '!')" "$*"; }
fail() { printf '%s %s\n' "$(red '✗')" "$*"; exit 1; }

# ── Detect OS ─────────────────────────────────────────────
case "$(uname -s)" in
  Darwin*)              OS="mac" ;;
  Linux*)               OS="linux" ;;
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  *) fail "Unsupported OS: $(uname -s). Open an issue if you'd like support added." ;;
esac
info "Detected OS: $(green "$OS")"

# ── Ensure jq is installed ────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  info "jq already installed: $(jq --version)"
else
  warn "jq not found — installing..."
  case "$OS" in
    mac)
      if command -v brew >/dev/null 2>&1; then
        brew install jq
      else
        fail "Homebrew not installed. Install it from https://brew.sh, then re-run this script."
      fi
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y jq
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y jq
      elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y jq
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm jq
      elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y jq
      elif command -v apk >/dev/null 2>&1; then
        sudo apk add --no-cache jq
      else
        fail "Could not detect a package manager (apt/dnf/yum/pacman/zypper/apk). Install jq manually then re-run."
      fi
      ;;
    windows)
      if command -v choco >/dev/null 2>&1; then
        choco install -y jq
      elif command -v scoop >/dev/null 2>&1; then
        scoop install jq
      elif command -v winget >/dev/null 2>&1; then
        winget install --id stedolan.jq -e --accept-source-agreements --accept-package-agreements
      else
        fail "Install Chocolatey, Scoop, or winget — or download jq from https://jqlang.org/download — then re-run."
      fi
      ;;
  esac
  command -v jq >/dev/null 2>&1 || fail "jq install failed. Install it manually and re-run."
  info "jq installed: $(jq --version)"
fi

# ── Ensure ~/.claude exists ───────────────────────────────
mkdir -p "$TARGET_DIR"

# ── Backup existing statusline if present ────────────────
if [ -f "$TARGET_SCRIPT" ]; then
  BAK="${TARGET_SCRIPT}.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$TARGET_SCRIPT" "$BAK"
  info "Backed up existing script → $BAK"
fi

# ── Copy script ───────────────────────────────────────────
cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
info "Installed script → $TARGET_SCRIPT"

# ── Patch settings.json (preserve existing keys) ─────────
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "${SETTINGS}.bak.$(date +%Y%m%d-%H%M%S)"
  jq '.statusLine = {"type": "command", "command": "sh ~/.claude/statusline.sh", "padding": 0}' "$SETTINGS" \
    > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
  info "Patched $SETTINGS (existing settings preserved)"
else
  jq -n '{statusLine: {type: "command", command: "sh ~/.claude/statusline.sh", padding: 0}}' > "$SETTINGS"
  info "Created $SETTINGS"
fi

# ── Done ──────────────────────────────────────────────────
echo
info "$(green 'Installed.') Send any new message in Claude Code to see the new status line."
echo "  Update later with:    bash ${SCRIPT_DIR}/update.sh"
echo "  Uninstall with:       bash ${SCRIPT_DIR}/uninstall.sh"
