# terminalconfig

My terminal tool configuration — Zsh, Tmux, Neovim, Yazi, Ghostty, Harlequin, OpenCode.

## Quick Install

```bash
# On a fresh Ubuntu 24.04+ system:
bash <(curl -fsSL https://raw.githubusercontent.com/deanlipowicz/terminalconfig/main/install.sh)
```

Or clone and run locally:

```bash
git clone https://github.com/deanlipowicz/terminalconfig.git ~/terminalconfig
cd ~/terminalconfig
./install.sh
```

## What it installs

| Phase | What |
|-------|------|
| 01-packages | apt packages, Rust/Cargo tools, pipx, uv, npm globals |
| 02-fonts | JetBrains Mono Nerd Font |
| 03-oh-my-zsh | Oh My Zsh, Powerlevel10k theme, zsh-autosuggestions, zsh-syntax-highlighting |
| 04-deploy | Backs up existing configs, symlinks repo configs to correct locations |

## What gets configured

| Tool | Config location in repo |
|------|------------------------|
| Ghostty | `config/ghostty/config` |
| Harlequin | `config/harlequin/config.toml` |
| Neovim | `config/nvim/` (LazyVim-based) |
| OpenCode | `config/opencode/opencode.jsonc` |
| Yazi | `config/yazi/` |
| Zsh | `home/.zshrc.tmpl` → `~/.zshrc` |
| Tmux | `home/.tmux.conf` → `~/.tmux.conf` |
| Git | `home/.gitconfig` → `~/.gitconfig` |

## Override semantics

The bootstrap **replaces** existing configs with the repo versions.
Originals are backed up to `~/.config-bak/YYYY-MM-DD_HHMMSS/`.

To restore:
```bash
cp -r ~/.config-bak/2026-07-03_120000/* ~/
```

To skip a phase, comment it out in `install.sh`.

## Syncing local changes back

After modifying configs locally, sync them back to the repo:

```bash
cd ~/terminalconfig
./push-config.sh
git diff
git add -A && git commit -m "sync: capture local config changes"
git push
```

## Template variables

Machine-specific values use `{{VAR}}` syntax in `.tmpl` files.
Override defaults via environment variables:

```bash
PYTHON_HOST_PROG=/usr/bin/python3 ./install.sh
```
