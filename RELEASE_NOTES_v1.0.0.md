# claude-statusline v1.0.0

Initial public release of a multi-line, color-coded status line for [Claude Code](https://claude.com/claude-code).

![preview](./assets/preview.svg)

---

## What it shows

**Line 1 — session**
Model · account (subscription tier or API) · context bar with threshold colors · cost + session burn rate ($/hr) · 5-hour and 7-day rate limits · wall-clock time.

**Line 2 — workspace**
Folder · last-turn token usage (input / output / cache) · lines added/removed · git branch with ahead/behind upstream and dirty state · stash count.

**Line 3 — mode (only when relevant)**
Permission mode (`default` / `acceptEdits` / `plan` / `bypass`) · output style (when non-default) · battery (macOS only) · last commit.

Full per-element breakdown with examples in the [README anatomy section](./README.md#anatomy).

---

## Install

```bash
git clone https://github.com/ak-singla/claude-statusline ~/.claude-statusline
bash ~/.claude-statusline/install.sh
```

The installer:

- Auto-installs `jq` if missing — via Homebrew, apt, dnf, yum, pacman, zypper, apk, Chocolatey, Scoop, or winget (auto-detected).
- Patches `~/.claude/settings.json` while preserving every other setting you have.
- Backs up anything it overwrites.

Send a new message in Claude Code and the status line is live.

---

## Highlights

- **Account-aware** — surfaces which Claude account you're logged into, distinguishes `(Sub · Max 20x)` from `(API)` so you never wonder which billing path a session is going through.
- **Burn rate** — dollars-per-hour computed from session cost ÷ duration, shown next to the running total.
- **Threshold colors** — context %, 5h, 7d, and battery all color-shift green → yellow → red so problems jump out without you reading numbers.
- **Smart suppression** — line 3 vanishes when there's nothing interesting (default mode + default style + non-Mac + no git repo). No empty-line clutter.
- **Cross-platform** — one script, three OSes. macOS, Linux, and Windows via Git Bash / MSYS2 / WSL. OS-specific bits (battery, Windows path normalization) are gated cleanly.
- **Cheap** — pure bash + jq. No Python, no Node, no background daemons. The full render is a few milliseconds.
- **Reversible** — `uninstall.sh` cleanly removes the statusLine block from settings and restores the default.

---

## Requirements

| | |
|---|---|
| **OS** | macOS · Linux · Windows (Git Bash / MSYS2 / WSL) |
| **Shell** | bash |
| **Required** | `jq` (auto-installed) |
| **Optional** | `git` (silently skipped if absent) |

Native Windows PowerShell is **not** supported — use Git Bash or WSL.

---

## Update

```bash
bash ~/.claude-statusline/update.sh
```

Fast-forwards the repo and refreshes the script. No settings changes.

---

## Uninstall

```bash
bash ~/.claude-statusline/uninstall.sh
```

Removes the `statusLine` block from `settings.json` (preserving every other key) and deletes the script. Backups are kept.

---

## Known limitations

- **Battery is macOS-only.** Linux and Windows skip it cleanly. PRs welcome for Linux (`upower` / `/sys/class/power_supply`) and Windows (`WMIC` / PowerShell).
- **Git ahead/behind** requires an upstream tracking branch. Set one with `git branch --set-upstream-to=origin/<branch>`.
- The script reads `~/.claude.json` for OAuth account info. If Anthropic changes that file's schema in a future Claude Code release, the account label may go blank until the script is updated.

---

## License

[MIT](./LICENSE) — use it however you want.

---

## Credits

Built and maintained by [@ak-singla](https://github.com/ak-singla). If this saves you time, a ⭐ on the repo is the kindest possible thanks.
