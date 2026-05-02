# claude-statusline v1.0.1

Windows install reliability release. No changes to the rendered status line itself — every fix is in the install/uninstall/update path.

---

## Why this release

The v1.0.0 install instructions told users to run:

```bash
git clone https://github.com/ak-singla/claude-statusline ~/.claude-statusline
bash ~/.claude-statusline/install.sh
```

On Windows, that line gets pasted into PowerShell or `cmd.exe` as often as into Git Bash — and PowerShell / cmd do **not** expand `~`. Result: `git` creates a literal `~` folder at `C:\Users\<you>\~\.claude-statusline\`, and `bash ~/.claude-statusline/install.sh` then fails to find anything. Even when users do run from Git Bash, the generated `settings.json` referenced bare `bash` and `~`, both of which Claude Code can resolve to the wrong thing depending on how it spawns the command (`C:\Windows\System32\bash.exe` is the WSL launcher, which silently fails on Windows-style script paths).

v1.0.1 makes Windows install bulletproof.

---

## What changed

### New: PowerShell-native install scripts

- `install.ps1` — Windows PowerShell counterpart to `install.sh`. Uses `$env:USERPROFILE`, finds Git Bash at standard install paths (rejects `System32\bash.exe`), auto-installs `jq` via Chocolatey / Scoop / winget.
- `uninstall.ps1`, `update.ps1` — round-trip parity with the bash equivalents.

### New: `.cmd` wrapper on Windows

Both `install.sh` (when running on Windows) and `install.ps1` now write a tiny `~/.claude/statusline.cmd` wrapper that invokes Git Bash's `bash.exe` with the absolute statusline path. The `settings.json` `statusLine.command` is then just an absolute path to that wrapper:

```json
"command": "C:/Users/<you>/.claude/statusline.cmd"
```

This sidesteps three failure modes:

1. **Path-with-spaces quoting.** No more `"C:\Program Files\Git\bin\bash.exe"` in the JSON command, so Claude Code's spawn (whatever shape it takes — `cmd /c`, direct exec, child_process spawn) can't mangle it.
2. **PATH-resolved `bash` hitting WSL.** The wrapper hard-codes Git Bash's absolute path; even on systems where `bash` resolves to `C:\Windows\System32\bash.exe`, the statusline still runs.
3. **`~` expansion at runtime.** All paths are absolute, so no shell needs to expand `~`.

### `update.sh` / `update.ps1` now delegate to install

The old update scripts only refreshed `statusline.sh`. v1.0.1 has them re-run the full installer after the git pull, so the wrapper, the bash-path detection, and the settings.json command stay in sync with future versions.

### README

- Added a Windows PowerShell quick-install section.
- Added a `~`-expansion warning above the bash command.
- OS support table now lists the PowerShell installer alongside Git Bash / MSYS2.

---

## Validation matrix

| Configuration | Tested on this release |
|---|---|
| Windows PowerShell `install.ps1` (fresh + re-run + over existing settings) | ✓ |
| Windows Git Bash `install.sh` | ✓ |
| Windows `uninstall.ps1` round-trip | ✓ |
| Windows `uninstall.sh` round-trip | ✓ |
| Windows `update.ps1` (delegates to install) | ✓ |
| Windows `update.sh` (delegates to install) | ✓ |
| Wrapper invocation through `cmd /c`, direct call, and `Process.Start` | ✓ |
| Settings.json patching preserves every non-statusLine key | ✓ |
| macOS / Linux `install.sh` | code review only — no behavior change for these paths beyond writing an absolute `$HOME` path instead of `~` |

---

## Upgrading from v1.0.0

```bash
# macOS / Linux / Git Bash
bash ~/.claude-statusline/update.sh

# Windows PowerShell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude-statusline\update.ps1"
```

The updater fast-forwards the repo and re-runs the installer, which produces the new `.cmd` wrapper on Windows and refreshes `settings.json`. Existing keys outside `statusLine` are preserved; backups of the old `statusline.sh` are kept.

If you previously ran into the `~` folder issue, also delete the stray clone manually:

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\~"
```

---

## License

[MIT](./LICENSE).
