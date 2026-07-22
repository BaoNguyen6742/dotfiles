# Package requirements and verification

This guide documents the user-level packages under `packages/`. Start with the installation workflow in the [main README](../README.md). Package names below follow Arch Linux where possible; packages from the AUR may have a `-git` suffix.

## Common commands

Preview one or more packages before installing them:

```bash
./scripts/stow.sh --simulate --verbose PACKAGE...
./scripts/stow.sh --verbose PACKAGE...
```

Confirm that a managed destination is a symlink:

```bash
readlink ~/.config/nvim/init.lua
```

The output should point into this repository. The wrapper uses `--no-folding`, so writable application directories remain local and only managed files become symlinks.

## Shell packages

### `bash`

- **Destination:** `~/.bash_aliases`
- **Requires:** Bash
- **Note:** `.bashrc` must source `~/.bash_aliases`; many distributions do this automatically.
- **Verify:** `bash -n ~/.bash_aliases && source ~/.bash_aliases`

### `fish-linux` and `fish-wsl`

- **Destination:** `~/.config/fish/config.fish`
- **Requires:** Fish
- **Conflict:** install exactly one of these packages.
- **WSL note:** `fish-wsl` defines aliases for `notepad++.exe` and `clip.exe`.
- **Verify:** `fish -n ~/.config/fish/config.fish && exec fish`

## Desktop shell packages

### `hypr`

- **Destination:** `~/.config/hypr`
- **Core requirements:** Hyprland, Hypridle, Hyprlock, Hyprpaper, and `hyprpolkitagent`
- **Commands used by bindings/startup:** `wezterm`, `thunar`, `rofi`, `dunst`, `wl-paste`, `wl-copy`, `cliphist`, `grim`, `slurp`, `swappy`, `wpctl`, `brightnessctl`, `playerctl`, `fcitx5`, `nm-applet`, `jq`, and `systemctl`
- **Related packages:** install `ags`, `assets`, `dunst`, `rofi`, `wezterm`, and `desktop` for the complete setup.

Important machine-specific settings:

- `hypr_conf/IO/core.conf` contains three exact monitor descriptions, modes, positions, and scales.
- `hypr_conf/Startup_and_Shutdown/core.conf` assigns workspaces to those same monitor descriptions.
- `mouse:276` is a hardware-specific side-button binding.
- The configuration expects the custom `UDEV Gothic 35NFLG` font. Install it separately or replace it with an available font.

Before using this package on another machine, inspect the connected monitors and update both monitor-related files:

```bash
hyprctl monitors all
```

Verify the configuration syntax:

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.conf
```

### `ags`

- **Destination:** `~/.config/ags`
- **Purpose:** GTK4 top bar used by the Hyprland startup configuration
- **Setup:** `./scripts/ags/setup.sh --generate-types`
- **Documentation:** see [AGS configuration](ags.md) for complete dependencies, hardware integration, development, and troubleshooting.

### `waybar`

- **Destination:** `~/.config/waybar`
- **Purpose:** fallback bar when AGS is unavailable
- **Requires:** Waybar, `wlogout`, NetworkManager, `nm-connection-editor`, PipeWire/WirePlumber, `wpctl`, `pactl`, `pavucontrol-qt`, `ip`, `awk`, and a Nerd Font
- **Hardware-specific helpers:**
  - `scripts/change_brightness.sh` expects DDC/CI buses `3`, `4`, and `5` and requires `ddcutil`.
  - `scripts/gpu.sh` is NVIDIA-specific and requires `nvidia-smi`.
  - `scripts/nightlight.sh` requires `hyprshade` and the shaders from the `hypr` package.

Check the machine-specific hardware before relying on those modules:

```bash
ddcutil detect
nvidia-smi
hyprshade current
```

Run individual helpers when troubleshooting:

```bash
~/.config/waybar/scripts/net_speed.sh
~/.config/waybar/scripts/gpu.sh usage
~/.config/waybar/scripts/change_brightness.sh
~/.config/waybar/scripts/nightlight.sh
```

### `dunst`

- **Destination:** `~/.config/dunst/dunstrc`
- **Requires:** Dunst, `notify-send` (normally from `libnotify`), a Nerd Font, and the Adwaita icon theme
- **Optional:** `dmenu` is configured for notification context menus.
- **Verify:** start `dunst`, then run `notify-send "Dotfiles test" "Dunst is working"`.

### `rofi`

- **Destination:** `~/.config/rofi/config.rasi`
- **Requires:** Rofi and `/usr/share/rofi/themes/material.rasi`, supplied by the Arch `rofi` package
- **Verify:** `rofi -show drun`

### `desktop`

This package manages GTK 3/4, Qt 5/6, Swappy, Swaylock, and MIME defaults.

- **Required applications:** `swappy`, `swaylock`, `qt5ct`, and `qt6ct` as applicable
- **Theme:** `Material-Black-Blueberry-3.38`, supplied on this machine by `material-black-colors-theme`
- **Icons:** Adwaita icon theme
- **Fonts:** `UDEV Gothic 35NFLG` and `JetBrainsMono Nerd Font`
- **Assets:** install the `assets` package for the Swaylock background.
- **Portability:** `mimeapps.list` names applications installed on the source machine; unavailable handlers are harmless but should be reviewed on a new system.

Useful checks:

```bash
gtk4-demo  # optional GTK theme check
qt5ct
qt6ct
swappy --help
swaylock --help
```

## Terminal and editor packages

### `wezterm`

- **Destination:** `~/.config/wezterm`
- **Requires:** WezTerm, Fish, and `JetBrainsMono Nerd Font`
- **Assets:** install `assets`; the background is `~/Documents/Pic/bg_2B.png`.
- **Verify:**

```bash
wezterm --config-file ~/.config/wezterm/wezterm.lua show-keys --lua >/dev/null
```

### `nvim`

- **Destination:** `~/.config/nvim`
- **Requires:** Neovim 0.11 or newer and Git
- **Recommended tooling:** `base-devel`, `make`, `ripgrep`, `fd`, `unzip`, `curl`, Node.js/npm, and Python/pip
- **Managed automatically:** `lazy.nvim` installs plugins; Mason installs configured language servers, formatters, and linters.
- **Documentation:** see the [Neovim package README](../packages/nvim/.config/nvim/README.md).

### `btop`

- **Destination:** `~/.config/btop/btop.conf`
- **Requires:** btop
- **Portability:** sensor and GPU availability differ by machine; adjust selections in btop's options menu.
- **Verify:** `btop`

## Data and application packages

### `assets`

- **Destination:** `~/Documents/Pic`
- **Contains:** backgrounds used by Hyprlock, Swaylock, WezTerm, and SDDM, plus the optimized 512×512 `face-lock.png` avatar
- **Safety:** `face-lock.png` uses a distinct filename so an existing full-resolution `~/Documents/Pic/face.png` is never managed or replaced.
- **Note:** these are ordinary Git-tracked image files; installing the package only creates symlinks.

### `pi`

- **Destination:** `~/.pi/agent`
- **Security:** credentials, sessions, installed package caches, and runtime state are intentionally excluded.
- **Documentation:** see [Pi configuration](pi.md).

## System package

SDDM is intentionally separate from the user-level packages because it targets `/etc` and `/usr/local`. See the dedicated [SDDM guide](sddm.md).

## General troubleshooting

List links owned by Stow:

```bash
find ~/.config -type l -lname '*dotfiles*' -print
```

Preview link repair after moving or pulling the repository:

```bash
./scripts/stow.sh --simulate --restow PACKAGE...
```

If Stow reports a conflict, compare and back up that individual destination. Do not use `--adopt` unless you intend to import the destination's contents into Git and review the resulting diff.
