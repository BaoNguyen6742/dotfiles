# Dotfiles

Configuration shared between Arch Linux, WSL, and Windows. Unix-like systems use [GNU Stow](https://www.gnu.org/software/stow/) to create symlinks from `$HOME` into this repository.

## Available packages

| Package | Destination | Use on |
|---|---|---|
| `bash` | `~/.bash_aliases` | Arch Linux or WSL |
| `fish-linux` | `~/.config/fish/config.fish` | Arch Linux |
| `fish-wsl` | `~/.config/fish/config.fish` | WSL |
| `ags` | `~/.config/ags/` | Arch Linux with Hyprland |
| `hypr` | `~/.config/hypr/` | Arch Linux with Hyprland |
| `nvim` | `~/.config/nvim/` | Arch Linux or WSL |
| `wezterm` | `~/.config/wezterm/` | Arch Linux |
| `dunst` | `~/.config/dunst/` | Arch Linux |
| `rofi` | `~/.config/rofi/` | Arch Linux |
| `btop` | `~/.config/btop/` | Arch Linux or WSL |
| `waybar` | `~/.config/waybar/` | Arch Linux; fallback for AGS |
| `desktop` | GTK, Qt, Swappy, Swaylock, and MIME defaults | Arch Linux |
| `assets` | `~/Documents/Pic/` | Images used by Hyprlock, Swaylock, and WezTerm |
| `pi` | `~/.pi/agent/` | Arch Linux or WSL |

Do not install `fish-linux` and `fish-wsl` together; they manage the same destination.

## Install on Arch Linux

### 1. Install Git and GNU Stow

```bash
sudo pacman -S --needed git stow
```

### 2. Clone the repository

```bash
git clone https://github.com/BaoNguyen6742/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 3. Preview the installation

For the complete Arch setup:

```bash
./scripts/stow.sh --simulate --verbose \
  bash fish-linux ags hypr nvim wezterm dunst rofi btop waybar desktop assets pi
```

The preview does not modify your home directory. If Stow reports a conflict, back up or remove the existing destination and run the preview again. For example:

```bash
mv ~/.bash_aliases ~/.bash_aliases.pre-stow
```

Handle each reported path individually. Do not use `stow --adopt` unless you intend to replace the repository version with the existing local file and will review the resulting Git diff.

### 4. Create the symlinks

```bash
./scripts/stow.sh --verbose \
  bash fish-linux ags hypr nvim wezterm dunst rofi btop waybar desktop assets pi
```

You can install only selected packages by listing fewer names. For example:

```bash
./scripts/stow.sh --verbose bash fish-linux
```

### 5. Finish setup

Reload the installed shell configuration:

```bash
source ~/.bash_aliases  # when using Bash
exec fish               # when using Fish
```

If you installed AGS, generate its local Astal TypeScript definitions:

```bash
./scripts/ags/setup.sh --generate-types
```

Restart Pi after installing the `pi` package, then authenticate with `/login` if needed.

The `assets` package installs the images required by Hyprlock, Swaylock, and WezTerm:

```text
~/Documents/Pic/bg_2B_sddm.png
~/Documents/Pic/bg_2B.png
~/Documents/Pic/face.png
```

Install `assets` alongside those packages. Its `face.png` is an optimized 512×512 copy for the lock screen; the original full-resolution image is not tracked. Install the Material GTK theme separately if using the `desktop` package. Theme assets under `~/.themes` are intentionally not tracked.

## Install the SDDM system configuration

SDDM is managed separately because its configuration lives under `/etc` and `/usr/local`, outside your home directory. The `sddm` system package installs a self-contained `sugar-candy-dotfiles` theme without modifying the package-owned theme under `/usr/share`.

Install the required tools:

```bash
sudo pacman -S --needed sddm stow acl
```

If the repository is below a private mode-`0700` home directory, allow only the `sddm` user to traverse the home directory and read the linked theme:

```bash
sudo setfacl -m u:sddm:x "$HOME"
sudo -u sddm test -r \
  "$PWD/system-packages/sddm/usr/local/share/sddm/themes/sugar-candy-dotfiles/Main.qml"
```

Preview the system links:

```bash
sudo ./scripts/stow-system.sh --simulate --verbose sddm
```

The existing `/etc/sddm.conf` will initially conflict. Back it up rather than deleting it permanently, remove the original, and preview again:

```bash
sudo cp -a /etc/sddm.conf /etc/sddm.conf.pre-stow
sudo rm /etc/sddm.conf
sudo ./scripts/stow-system.sh --simulate --verbose sddm
```

Install when the second preview is clean:

```bash
sudo ./scripts/stow-system.sh --verbose sddm
```

Optionally preview the theme in a window before activating it:

```bash
sddm-greeter-qt6 --test-mode --theme \
  "$PWD/system-packages/sddm/usr/local/share/sddm/themes/sugar-candy-dotfiles"
```

Reboot to apply it. Running `sudo systemctl restart sddm` also applies it, but immediately ends the current graphical session.

To remove the links and restore the previous configuration:

```bash
sudo ./scripts/stow-system.sh --delete sddm
sudo mv /etc/sddm.conf.pre-stow /etc/sddm.conf
```

## Install on WSL

### 1. Install Git and GNU Stow

On Ubuntu or Debian-based WSL distributions:

```bash
sudo apt update
sudo apt install git stow
```

### 2. Clone and preview

```bash
git clone https://github.com/BaoNguyen6742/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/stow.sh --simulate --verbose bash fish-wsl pi
```

Back up any conflicting destination files reported by Stow, then install:

```bash
./scripts/stow.sh --verbose bash fish-wsl pi
```

Reload your shell with `source ~/.bash_aliases` or `exec fish`. See [`docs/fish-wsl.md`](docs/fish-wsl.md) for the WSL-specific Fish configuration.

## Install Pi configuration on Windows

GNU Stow is not required on Windows. Clone the repository, open PowerShell in it, and run the copy-and-backup installer:

```powershell
git clone https://github.com/BaoNguyen6742/dotfiles.git "$HOME\.dotfiles"
Set-Location "$HOME\.dotfiles"

# Preview without changing files
.\scripts\pi\install.ps1 -DryRun

# Install
.\scripts\pi\install.ps1
```

If PowerShell blocks script execution for the current process:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Restart Pi after installation and authenticate with `/login`. See [`docs/pi.md`](docs/pi.md) for details.

## Updating

Pull the latest changes and refresh the links for the packages installed on that machine:

```bash
cd ~/.dotfiles
git pull
./scripts/stow.sh --restow \
  bash fish-linux ags hypr nvim wezterm dunst rofi btop waybar desktop assets pi
```

On WSL, use `fish-wsl` instead of `fish-linux` and omit `ags` unless it is needed.

On Windows, run `git pull` and rerun `scripts/pi/install.ps1`.

## Uninstalling

Remove a package's symlinks without deleting repository files:

```bash
cd ~/.dotfiles
./scripts/stow.sh --delete ags
```

List multiple package names to remove several packages at once.

## AGS notes

The optional CPU wattage helper requires privilege escalation and can be installed separately:

```bash
./scripts/ags/setup.sh --install-rapl-helper
```

Files edited through `~/.config/ags` are symlinks into this repository, so changes appear directly in `git diff`; no capture step is needed. See [`docs/ags.md`](docs/ags.md) for dependencies, Hyprland startup, and usage.

## Repository layout

```text
packages/
├── bash/
├── fish-linux/
├── fish-wsl/
├── ags/
├── hypr/
├── nvim/
├── wezterm/
├── dunst/
├── rofi/
├── btop/
├── waybar/
├── desktop/
├── assets/
└── pi/
system-packages/
└── sddm/
scripts/
├── stow.sh
├── stow-system.sh
├── ags/setup.sh
└── pi/install.ps1
docs/
```

The Stow wrapper uses `--no-folding`, ensuring writable directories such as `~/.pi` and generated AGS directories remain outside the repository.
