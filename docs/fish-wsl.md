# Fish on WSL

Install the WSL-specific Fish package from the repository root:

```bash
./scripts/stow.sh --simulate --verbose fish-wsl
./scripts/stow.sh --verbose fish-wsl
```

Do not install `fish-linux` at the same time because both packages manage `~/.config/fish/config.fish`.

This configuration expects Notepad++ as its editor. Change the editor setting in `packages/fish-wsl/.config/fish/config.fish` if needed.
