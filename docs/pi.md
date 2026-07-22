# Pi configuration

The Stow package at `packages/pi/` contains the portable part of the global Pi configuration:

- `.pi/agent/settings.json` — preferences and package declarations
- `.pi/agent/extensions/` — user-authored extension source

Runtime data is intentionally not tracked. Authenticate separately on each machine; never copy `auth.json`, sessions, caches, installed packages, or checkpoints into this repository.

## Arch Linux and WSL

From the repository root, preview and install the package:

```bash
./scripts/stow.sh --simulate --verbose pi
./scripts/stow.sh --verbose pi
```

The wrapper uses `--no-folding`. This is important for Pi: it keeps `~/.pi` and `~/.pi/agent` as normal local directories and links only the managed settings and extension files. Pi can then create credentials and runtime state without writing them into the repository.

## Windows PowerShell

From the repository root, run:

```powershell
.\scripts\pi\install.ps1 -DryRun
.\scripts\pi\install.ps1
```

If script execution is blocked for the current process, run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

The Windows installer copies the tracked files from `packages/pi/.pi/agent` into `${PI_CODING_AGENT_DIR}` or `$HOME/.pi/agent`, and backs up changed destination files before replacing them.

After installation, start Pi. It will install missing packages declared in `settings.json`. Sign in with `/login` on each machine. Restart Pi after later settings updates; `/reload` is enough when only extension source changed.

## Updating

On Unix-like systems, editing a managed file through `~/.pi/agent` edits the repository through its symlink. After pulling changes, run:

```bash
./scripts/stow.sh --restow pi
```

On Windows, rerun `scripts/pi/install.ps1` after pulling.

Pi may add machine-local fields such as `lastChangelogVersion` to a copied Windows settings file; those fields are intentionally omitted here. The Windows installer does not delete unrelated extensions. If a tracked extension is removed or renamed, manually remove its old copied version on Windows.
