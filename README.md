# Dotfiles

Configuration shared between Windows, WSL, and Arch Linux.

## Installation

Shell configuration folders contain their own installer. When a folder has platform subdirectories, pass the platform name:

```bash
cd fish
./install.fish Linux
```

Pi has separate installers for Arch/Linux and Windows PowerShell.

Arch/Linux:

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
