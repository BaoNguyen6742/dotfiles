# Pi configuration

This directory contains the portable part of the global Pi configuration:

- `settings.json` — preferences and package declarations
- `extensions/` — user-authored extension source

Runtime data is intentionally not tracked. Authenticate separately on each machine; never copy `auth.json`, sessions, caches, installed packages, or checkpoints into this repository.

## Arch Linux

```bash
cd pi
./install.sh --dry-run
./install.sh
```

The installer copies files to `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}` and backs up changed destination files before replacing them.

## Windows PowerShell

```powershell
cd pi
.\install.ps1 -DryRun
.\install.ps1
```

If script execution is blocked for the current process, run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

After installation, start Pi. It will install missing packages declared in `settings.json`. Sign in with `/login` on each machine. Restart Pi after later settings updates; `/reload` is enough when only extension source changed.

## Updating

Edit the tracked files in this directory, commit and push them, pull on the other machine, and rerun its installer. Pi may add machine-local fields such as `lastChangelogVersion` to the installed copy; those fields are intentionally omitted here.

The installers do not delete other files from `~/.pi/agent/extensions`, so unrelated local extensions remain safe. If you remove or rename an extension in this repository, manually remove its old installed copy too.
