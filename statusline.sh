#!/bin/bash
# Claude Code Statusline - Full Featured (macOS + Windows/Git Bash)
# Requires: jq (brew install jq / apt install jq / choco install jq)

input=$(cat)

# ── OS detection ─────────────────────────────────────────
case "$(uname -s 2>/dev/null)" in
  Darwin*) IS_MAC=1 ;;
  *)       IS_MAC=0 ;;
esac

# ── Colors ───────────────────────────────────────────────
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[91m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
BLUE=$'\033[34m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# ── Extract fields via jq ────────────────────────────────
MODEL=$(echo "$input"      | jq -r '.model.display_name // "?"')
CTX_PCT=$(echo "$input"    | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
IN_TOK=$(echo "$input"     | jq -r '.context_window.current_usage.input_tokens // 0')
OUT_TOK=$(echo "$input"    | jq -r '.context_window.current_usage.output_tokens // 0')
CACHE_R=$(echo "$input"    | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
CACHE_W=$(echo "$input"    | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
COST=$(echo "$input"       | jq -r '.cost.total_cost_usd // 0')
LINES_ADD=$(echo "$input"  | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$input"  | jq -r '.cost.total_lines_removed // 0')
DURATION=$(echo "$input"   | jq -r '.cost.total_duration_ms // 0')
RL5H_PCT=$(echo "$input"   | jq -r '.rate_limits.five_hour.used_percentage // 0' | cut -d. -f1)
RL5H_TS=$(echo "$input"    | jq -r '.rate_limits.five_hour.resets_at // 0')
RL7D_PCT=$(echo "$input"   | jq -r '.rate_limits.seven_day.used_percentage // 0' | cut -d. -f1)
CWD=$(echo "$input"        | jq -r '.workspace.current_dir // "."')
PERM_MODE=$(echo "$input"  | jq -r '.permission_mode // .permissionMode // ""')
OUT_STYLE=$(echo "$input"  | jq -r '.output_style.name // .outputStyle.name // .outputStyle // ""')

# ── Normalize Windows path (D:/foo or D:\foo → /d/foo) ───
case "$CWD" in
  [A-Za-z]:[/\\]*)
    drv=$(printf '%s' "$CWD" | cut -c1 | tr 'A-Z' 'a-z')
    rest=$(printf '%s' "$CWD" | cut -c3- | tr '\\' '/')
    CWD="/${drv}${rest}"
    ;;
esac

# ── Auth method (API key vs Subscription) ────────────────
AUTH_LABEL=""
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  AUTH_LABEL="API"
elif [ -f "$HOME/.claude.json" ]; then
  HAS_OAUTH=$(jq -r 'has("oauthAccount") and ((.oauthAccount.emailAddress // "") != "")' "$HOME/.claude.json" 2>/dev/null)
  [ "$HAS_OAUTH" = "true" ] && AUTH_LABEL="Sub"
fi

# ── Account string (email · auth · tier) ─────────────────
ACCT_STR=""
if [ -f "$HOME/.claude.json" ]; then
  ACCT_EMAIL=$(jq -r '.oauthAccount.emailAddress // ""' "$HOME/.claude.json" 2>/dev/null)
  ACCT_TIER_RAW=$(jq -r '.oauthAccount.organizationRateLimitTier // ""' "$HOME/.claude.json" 2>/dev/null)
  case "$ACCT_TIER_RAW" in
    default_claude_max_20x) ACCT_TIER="Max 20x" ;;
    default_claude_max_5x)  ACCT_TIER="Max 5x"  ;;
    default_claude_pro)     ACCT_TIER="Pro"     ;;
    default_claude_team)    ACCT_TIER="Team"    ;;
    *)                      ACCT_TIER=""        ;;
  esac
  if [ -n "$ACCT_EMAIL" ]; then
    if [ "$AUTH_LABEL" = "API" ]; then
      LABEL_PART="API"
    elif [ -n "$ACCT_TIER" ]; then
      LABEL_PART="Sub · ${ACCT_TIER}"
    else
      LABEL_PART="Sub"
    fi
    ACCT_STR="👤 ${MAGENTA}${ACCT_EMAIL}${RESET} ${DIM}(${LABEL_PART})${RESET}"
  fi
fi
if [ -z "$ACCT_STR" ] && [ "$AUTH_LABEL" = "API" ]; then
  ACCT_STR="👤 ${MAGENTA}API key${RESET}"
fi

# ── Permission mode label ────────────────────────────────
case "$PERM_MODE" in
  default)            PERM_STR="${DIM}▶ default${RESET}" ;;
  acceptEdits)        PERM_STR="${YELLOW}▶ acceptEdits${RESET}" ;;
  plan)               PERM_STR="${BLUE}📋 plan${RESET}" ;;
  bypassPermissions)  PERM_STR="${RED}▶ bypass${RESET}" ;;
  "")                 PERM_STR="" ;;
  *)                  PERM_STR="${DIM}▶ ${PERM_MODE}${RESET}" ;;
esac

# ── Output style label (only render when non-default) ────
case "$OUT_STYLE" in
  ""|default|Default) OUT_STR="" ;;
  *)                  OUT_STR="${CYAN}🎨 ${OUT_STYLE}${RESET}" ;;
esac

# ── Context bar (10 chars) ───────────────────────────────
build_bar() {
  local pct=$1 width=10
  local filled=$(( pct * width / 100 ))
  local bar=""
  for ((i=0; i<filled; i++));    do bar+="█"; done
  for ((i=filled; i<width; i++)); do bar+="░"; done
  echo "$bar"
}

CTX_BAR=$(build_bar "$CTX_PCT")

# ── Color by threshold ───────────────────────────────────
color_by_pct() {
  local pct=$1
  if   [ "$pct" -lt 50 ]; then echo "$GREEN"
  elif [ "$pct" -lt 80 ]; then echo "$YELLOW"
  else                         echo "$RED"
  fi
}

CTX_COLOR=$(color_by_pct "$CTX_PCT")
RL5_COLOR=$(color_by_pct "$RL5H_PCT")
RL7_COLOR=$(color_by_pct "$RL7D_PCT")

# ── 5h reset: human-readable time remaining ─────────────
if [ "$RL5H_TS" -gt 0 ] 2>/dev/null; then
  NOW=$(date +%s)
  DIFF=$(( RL5H_TS - NOW ))
  if [ "$DIFF" -gt 0 ]; then
    HRS=$(( DIFF / 3600 ))
    MINS=$(( (DIFF % 3600) / 60 ))
    RESET_STR="${HRS}h${MINS}m"
  else
    RESET_STR="soon"
  fi
else
  RESET_STR="?"
fi

# ── Session duration & burn rate ($/hr) ──────────────────
DUR_STR=""
BURN_STR=""
if [ "$DURATION" -gt 0 ] 2>/dev/null; then
  DUR_MIN=$(( DURATION / 60000 ))
  if [ "$DUR_MIN" -gt 0 ]; then
    DUR_STR="${DUR_MIN}m"
  else
    DUR_STR="<1m"
  fi
  BURN_STR=$(awk -v c="$COST" -v d="$DURATION" 'BEGIN{ if(d>0 && c>0){printf "%.2f", c*3600000/d} else print "" }')
fi

# ── Cost formatted ───────────────────────────────────────
COST_FMT=$(printf '%.3f' "$COST")

# ── Current time ─────────────────────────────────────────
CURRENT_TIME=$(date "+%H:%M:%S")

# ── Cache total (read + write) ───────────────────────────
CACHE_TOT=$(( CACHE_R + CACHE_W ))

# ── Battery (macOS only — pmset reads cached IOKit state, ~free) ─
BAT_STR=""
if [ "$IS_MAC" = "1" ] && command -v pmset >/dev/null 2>&1; then
  BAT_RAW=$(pmset -g batt 2>/dev/null)
  BAT_PCT=$(echo "$BAT_RAW" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
  BAT_STATE=$(echo "$BAT_RAW" | grep -Eo '(charging|discharging|charged|AC attached|finishing charge|not charging)' | head -1)
  if [ -n "$BAT_PCT" ]; then
    case "$BAT_STATE" in
      charging|charged|"AC attached"|"finishing charge") BAT_ICON="🔌" ;;
      *) BAT_ICON="🔋" ;;
    esac
    if [ "$BAT_PCT" -lt 20 ]; then
      BAT_STR="${BAT_ICON} ${RED}${BAT_PCT}%${RESET}"
    elif [ "$BAT_PCT" -lt 50 ]; then
      BAT_STR="${BAT_ICON} ${YELLOW}${BAT_PCT}%${RESET}"
    else
      BAT_STR="${BAT_ICON} ${BAT_PCT}%"
    fi
  fi
fi

# ── Git: branch, ahead/behind, dirty counts, stash, last commit ──
GIT_STR=""
LAST_COMMIT=""
STASH_STR=""
if git -C "$CWD" rev-parse --git-dir > /dev/null 2>&1; then
  BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)
  STAGED=$(git -C "$CWD" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  MODIFIED=$(git -C "$CWD" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
  UNTRACKED=$(git -C "$CWD" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  AHEAD=0
  BEHIND=0
  AB=$(git -C "$CWD" rev-list --left-right --count HEAD...@{u} 2>/dev/null)
  if [ -n "$AB" ]; then
    AHEAD=$(echo "$AB"  | awk '{print $1}')
    BEHIND=$(echo "$AB" | awk '{print $2}')
  fi

  GIT_STR="⎇ ${CYAN}${BRANCH}${RESET}"
  [ "${AHEAD:-0}"     -gt 0 ] 2>/dev/null && GIT_STR+=" ${GREEN}↑${AHEAD}${RESET}"
  [ "${BEHIND:-0}"    -gt 0 ] 2>/dev/null && GIT_STR+=" ${RED}↓${BEHIND}${RESET}"
  [ "${STAGED:-0}"    -gt 0 ] 2>/dev/null && GIT_STR+=" ${GREEN}+${STAGED}✓${RESET}"
  [ "${MODIFIED:-0}"  -gt 0 ] 2>/dev/null && GIT_STR+=" ${YELLOW}~${MODIFIED}${RESET}"
  [ "${UNTRACKED:-0}" -gt 0 ] 2>/dev/null && GIT_STR+=" ${DIM}?${UNTRACKED}${RESET}"

  LAST_COMMIT=$(git -C "$CWD" --no-optional-locks log -1 --format="%h %s" 2>/dev/null | cut -c1-60)

  STASH_COUNT=$(git -C "$CWD" stash list 2>/dev/null | wc -l | tr -d ' ')
  if [ "${STASH_COUNT:-0}" -gt 0 ] 2>/dev/null; then
    STASH_STR="📦 Stash: ${STASH_COUNT}"
  fi
fi

# ── Lines changed (from cost object) ─────────────────────
LINES_STR=""
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  LINES_STR=" ${GREEN}+${LINES_ADD}${RESET}/${RED}-${LINES_DEL}${RESET}"
fi

# ── Folder name only ─────────────────────────────────────
FOLDER="${CWD##*/}"

# ── Line 1: Session info ─────────────────────────────────
printf "${BOLD}%s${RESET}" "$MODEL"
[ -n "$ACCT_STR" ] && printf " │ %s" "$ACCT_STR"
printf " │ 🧠 ${CTX_COLOR}%s${RESET} %s%%" "$CTX_BAR" "$CTX_PCT"
printf " │ 💰 \$%s" "$COST_FMT"
if [ -n "$DUR_STR" ]; then
  if [ -n "$BURN_STR" ]; then
    printf " (%s · \$%s/hr)" "$DUR_STR" "$BURN_STR"
  else
    printf " (%s)" "$DUR_STR"
  fi
fi
printf " │ ⏱ 5h: ${RL5_COLOR}%s%%${RESET}→%s" "$RL5H_PCT" "$RESET_STR"
printf " │ 📅 7d: ${RL7_COLOR}%s%%${RESET}" "$RL7D_PCT"
printf " │ 🕐 %s" "$CURRENT_TIME"
printf "\n"

# ── Line 2: Folder + tokens + git + stash ────────────────
printf "📁 %s" "$FOLDER"
printf " │ 🔡 in:%s out:%s cache♻:%s" "$IN_TOK" "$OUT_TOK" "$CACHE_TOT"
printf "%s" "$LINES_STR"
[ -n "$GIT_STR" ]   && printf " │ %s" "$GIT_STR"
[ -n "$STASH_STR" ] && printf " │ %s" "$STASH_STR"
printf "\n"

# ── Line 3: Mode + output style + battery + last commit ──
LINE3=""
[ -n "$PERM_STR" ]    && LINE3="${PERM_STR}"
[ -n "$OUT_STR" ]     && LINE3="${LINE3:+${LINE3} │ }${OUT_STR}"
[ -n "$BAT_STR" ]     && LINE3="${LINE3:+${LINE3} │ }${BAT_STR}"
[ -n "$LAST_COMMIT" ] && LINE3="${LINE3:+${LINE3} │ }${DIM}⚙ ${LAST_COMMIT}${RESET}"
[ -n "$LINE3" ] && printf "%s\n" "$LINE3"
