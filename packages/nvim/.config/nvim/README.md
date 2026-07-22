# Neovim configuration

This is a Neovim 0.11+ configuration based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). It uses `lazy.nvim` for plugins and Mason for language servers and development tools.

## Requirements

Required:

- Neovim 0.11 or newer
- Git
- A Nerd Font for icons

Recommended system tooling:

```bash
sudo pacman -S --needed \
  base-devel ripgrep fd unzip curl nodejs npm python python-pip
```

`make` builds Telescope's native FZF extension. Node.js/npm and Python support tools installed by Mason.

## Install

From the dotfiles repository root:

```bash
./scripts/stow.sh --simulate --verbose nvim
./scripts/stow.sh --verbose nvim
```

On first launch, `lazy.nvim` clones itself into Neovim's data directory and installs the configured plugins. Mason then installs the configured tools, including TypeScript, Python, Docker, JSON, YAML, and Lua language servers plus Ruff, StyLua, shfmt, Prettier, and related formatters.

Start Neovim and allow the initial installations to finish:

```bash
nvim
```

## Verify

Inside Neovim, inspect the plugin and tool state:

```vim
:Lazy
:Mason
:checkhealth
```

Useful external checks:

```bash
nvim --version | head -1
rg --version
make --version | head -1
```

## Updating

Update the repository and refresh the Stow link:

```bash
git pull
./scripts/stow.sh --restow nvim
```

Then use `:Lazy update` for plugins and `:Mason` for language-server or formatter updates. Commit intentional changes to `lazy-lock.json` so other machines receive the same plugin revisions.

## Troubleshooting

- **Plugin installation failed:** confirm Git and network access, then open `:Lazy` and retry the failed operation.
- **Telescope live grep is unavailable:** install `ripgrep`.
- **The native FZF extension did not build:** install `base-devel` and `make`, then rebuild it through `:Lazy`.
- **Icons are boxes:** install a Nerd Font and configure the terminal to use it.
- **LSP or formatting is unavailable:** inspect `:Mason`, `:LspInfo`, `:NullLsInfo`, and `:checkhealth`.
- **A tool cannot be downloaded:** ensure `curl`, `unzip`, Node.js/npm, and Python are available as required by that tool.

Plugin data, Mason packages, caches, undo files, and sessions live outside this repository under Neovim's normal data/state directories.
