# Dotfiles

Configuration shared between Windows, WSL, and Arch Linux.

## Installation

Shell configuration folders contain their own installer. When a folder has platform subdirectories, pass the platform name:

```bash
cd fish
./install.fish Linux
```

AGS and Pi have installers that back up changed destination files before replacing them.

AGS top bar (Arch/Hyprland):

```bash
cd ags
./install.sh --dry-run
./install.sh --generate-types
```

To bring edits made directly in `~/.config/ags` back into the repository:

```bash
cd ags
./capture.sh --dry-run
./capture.sh
git diff -- .
```

Commit and push the reviewed changes, then run `./install.sh` after pulling them on another machine.

See [`ags/README.md`](ags/README.md) for system dependencies, Hyprland startup, and optional hardware integration.

Pi on Arch/Linux:

```bash
cd pi
./install.sh
```

Windows PowerShell:

```powershell
cd pi
.\install.ps1
```

See [`pi/README.md`](pi/README.md) for Pi package, extension, and authentication details.
