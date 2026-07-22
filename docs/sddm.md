# Stow-managed SDDM configuration

SDDM is a system service, so this package is separate from the user packages installed into `$HOME`.

## What is managed

```text
system-packages/sddm/
├── etc/sddm.conf
└── usr/local/share/sddm/themes/sugar-candy-dotfiles/
```

The configuration selects `sugar-candy-dotfiles`, enables Num Lock, and sets the theme directory to `/usr/local/share/sddm/themes`.

The theme is a self-contained copy of Sugar Candy with the local `Main.qml`, `Components/Input.qml`, colors, layout, and background customizations preserved. It lives under `/usr/local` rather than replacing `/usr/share/sddm/themes/sugar-candy`, so package upgrades cannot overwrite the managed theme. The upstream GPL license is included as `COPYING`.

## Requirements

On Arch Linux:

```bash
sudo pacman -S --needed sddm stow acl qt6-5compat qt6-declarative qt6-svg
```

`qt6-virtualkeyboard` is optional when the virtual keyboard component is used. The configured font is `JetBrainsMono Nerd Font`, normally supplied by `ttf-jetbrains-mono-nerd`.

## Repository access for the greeter

Stow creates links from `/etc` and `/usr/local` back into this repository. The SDDM greeter runs as the unprivileged `sddm` user and must be able to traverse the repository path.

If the repository is below a mode-`0700` home directory, grant only directory traversal—not directory listing—to the `sddm` user:

```bash
sudo setfacl -m u:sddm:x "$HOME"
```

Verify access from the service account:

```bash
sudo -u sddm test -r \
  "$PWD/system-packages/sddm/usr/local/share/sddm/themes/sugar-candy-dotfiles/Main.qml"
```

If the test fails, inspect every parent directory:

```bash
namei -l "$PWD/system-packages/sddm/usr/local/share/sddm/themes/sugar-candy-dotfiles/Main.qml"
```

An alternative is keeping the repository in an already readable location such as `/opt/dotfiles`.

## Preview and install

Run these commands from the repository root. First preview the system package:

```bash
sudo ./scripts/stow-system.sh --simulate --verbose sddm
```

An existing `/etc/sddm.conf` will conflict because Stow never overwrites regular files. Back it up and remove only the original path:

```bash
sudo cp -a /etc/sddm.conf /etc/sddm.conf.pre-stow
sudo rm /etc/sddm.conf
```

Preview again and install only when the conflict is gone:

```bash
sudo ./scripts/stow-system.sh --simulate --verbose sddm
sudo ./scripts/stow-system.sh --verbose sddm
```

Confirm the installed files are links:

```bash
readlink /etc/sddm.conf
readlink /usr/local/share/sddm/themes/sugar-candy-dotfiles/Main.qml
```

## Validate before activation

Validate QML statically from the repository:

```bash
theme="$PWD/system-packages/sddm/usr/local/share/sddm/themes/sugar-candy-dotfiles"
qmllint -I "$theme" "$theme/Main.qml"
```

Preview the greeter in a window:

```bash
sddm-greeter-qt6 --test-mode --theme "$theme"
```

The login form, background, avatar handling, session selector, and power buttons should render before the live display manager is changed.

## Activate

The safest activation is a reboot:

```bash
sudo reboot
```

Restarting SDDM directly also activates it, but immediately terminates the current graphical session:

```bash
sudo systemctl restart sddm
```

If SDDM does not start, switch to a TTY with `Ctrl+Alt+F2`, sign in, and inspect:

```bash
systemctl status sddm
journalctl -u sddm -b --no-pager
```

## Update

After pulling repository changes, refresh the links:

```bash
git pull
sudo ./scripts/stow-system.sh --restow sddm
```

A restow is normally sufficient because edits made through the links already change the repository files directly.

## Remove or recover

Remove only the Stow-managed links:

```bash
sudo ./scripts/stow-system.sh --delete sddm
```

Restore the pre-Stow configuration:

```bash
sudo mv /etc/sddm.conf.pre-stow /etc/sddm.conf
```

If the custom theme must be bypassed during recovery, create a minimal configuration selecting an installed theme under `/usr/share/sddm/themes`, or restore the backup before restarting SDDM.

## Security notes

- No passwords, user hashes, or authentication tokens are stored in this package.
- The password field in QML sends input to SDDM's authentication API; it does not contain a configured password.
- The ACL grants the `sddm` account traversal of the home directory only. Remove it after uninstalling if it is no longer needed:

  ```bash
  sudo setfacl -x u:sddm "$HOME"
  ```
- Keep the repository and theme files non-writable by the `sddm` user.
