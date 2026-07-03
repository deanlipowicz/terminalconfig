# terminalconfig — Design Spec

## Purpose

A single-command bootstrap system that installs and configures a complete terminal
environment (Zsh, Tmux, Neovim, Yazi, Ghostty, Harlequin, OpenCode) on any Linux
system. The repo is the source of truth for all config files; running `install.sh`
replaces existing configs in favor of this system's configuration.

## Repo Layout

```
terminalconfig/
├── config/                     mirrors ~/.config/<tool>/
│   ├── ghostty/config
│   ├── harlequin/config.toml
│   ├── nvim/                   plain copy of LazyVim config (no submodule)
│   ├── opencode/opencode.jsonc
│   └── yazi/
│       ├── yazi.toml
│       ├── keymap.toml
│       ├── theme.toml
│       ├── init.lua
│       └── package.toml
├── home/                       dotfiles that live in $HOME
│   ├── .zshrc.tmpl             rendered via template engine
│   ├── .tmux.conf
│   ├── .gitconfig
│   └── .p10k.zsh.tmpl          rendered via template engine
├── bootstrap/                  idempotent install phases
│   ├── lib.sh                  shared helpers (log, os-detect, backup, render)
│   ├── 01-packages.sh          apt + cargo + pipx + uv + npm
│   ├── 02-fonts.sh             JetBrains Mono Nerd Font
│   ├── 03-oh-my-zsh.sh         oh-my-zsh + plugins + powerlevel10k
│   └── 04-deploy.sh            backup + symlink + template render
├── install.sh                  entry point
├── push-config.sh              inverse of deploy — copies local config into repo
├── docs/superpowers/specs/     this document
└── README.md
```

## Bootstrap Phases

### 01-packages.sh
Installs all system and language-specific tooling.

**APT packages:**
- Shell: zsh
- Terminal multiplexer: tmux
- Editors: neovim, micro (if available)
- Terminal emulator: ghostty (via ppa:ghostty/ghostty on Ubuntu; see https://ghostty.org/docs/install)
- File manager: yazi
- Utilities: eza, fdfind, ripgrep, bat, git, curl, wget, xclip, unzip, fzf, jq, yq, zoxide
- Python: python3, python3-pip, python3-venv, python3-pygments

**Cargo (via rustup if needed):**
- git-delta (delta)
- cargo-update

**pipx:**
- harlequin

**uv:**
- pyright
- ruff
- cmake-language-server
- pre-commit

**npm global:**
- bash-language-server
- yaml-language-server
- typescript, typescript-language-server
- vscode-langservers-extracted
- prettier
- sql-language-server
- tree-sitter-cli
- tldr

**Fonts:** Installed in a separate phase (02-fonts) to keep concerns separated.

**Idempotency:** Each tool is checked via `which` or `command -v` before install.
Package managers use `--upgrade` or equivalent for already-installed tools.

### 02-fonts.sh
Downloads JetBrainsMono Nerd Font from the Nerd Fonts GitHub releases page,
extracts to `~/.local/share/fonts/`, and runs `fc-cache -f`.
Skips if the font files are already present.

### 03-oh-my-zsh.sh
Clones oh-my-zsh to `~/.oh-my-zsh` if missing.
Clones powerlevel10k theme to `~/.oh-my-zsh/custom/themes/powerlevel10k`.
Clones zsh-autosuggestions and zsh-syntax-highlighting to custom plugins.
Skips any step where the target directory already exists.

### 04-deploy.sh
The core deployment phase:

1. **Backup:** For every file that will be written, check if a file/symlink already
   exists at the target path. If so, copy it to `~/.config-bak/YYYY-MM-DD_HHMMSS/`
   preserving the relative path structure.

2. **Template rendering:** For `.tmpl` files, substitute `{{VAR_NAME}}` placeholders
   with values from a defaults file or environment variables. Non-templated files
   are copied/symlinked as-is.

3. **Symlink:** Files in `config/` are symlinked to `~/.config/<tool>/<filename>`.
   Files in `home/` are symlinked to `~/.<filename>` (without the `.tmpl` suffix
   for templates). The nvim directory is an exception — it is symlinked in its
   entirety as `~/.config/nvim -> <repo>/config/nvim`.

4. **Post-deploy:** Prints a summary of what was backed up and where.

## Template System

Files ending in `.tmpl` use `{{VAR_NAME}}` placeholders. Template variables are
defined at the top of each `.tmpl` file in comments so the file is self-documenting
and still usable if read directly.

Default values are hardcoded in `04-deploy.sh`. The install script accepts
overrides via environment variables (e.g., `PYTHON_HOST_PROG=/usr/bin/python3`).

Files requiring templating:
- `home/.zshrc.tmpl` — `CMDSTAN_HOME`, `HIP_VISIBLE_DEVICES`, `OPENCODE_PATH`
- `home/.p10k.zsh.tmpl` — (if needed, currently no machine-specific values)
- `config/nvim/lua/config/options.lua` — `python3_host_prog`

## Install Entry Point

```bash
# install.sh
cd "$(dirname "$0")"
source bootstrap/lib.sh
phase "System packages"    && bootstrap/01-packages.sh
phase "Nerd Fonts"         && bootstrap/02-fonts.sh
phase "Oh My Zsh"          && bootstrap/03-oh-my-zsh.sh
phase "Deploy configs"     && bootstrap/04-deploy.sh
```

The README documents a one-liner:
```bash
curl -fsSL https://raw.githubusercontent.com/deanlipowicz/terminalconfig/main/install.sh | bash
```

## Push Utility

`push-config.sh` copies the current local configs back into the repo structure,
intended to be run after making local changes. It is the inverse of `04-deploy.sh`:
it reads from `~/.config/<tool>/` and writes into `config/<tool>/`, and reads from
`~/.<dotfile>` and writes into `home/.<dotfile>`.

## Override Semantics

The system is designed to **replace** existing configurations. After install, the
machine runs terminalconfig's configuration. Partial installs are supported by
commenting out phases in `install.sh` or skipping individual phases.

Backups in `~/.config-bak/` provide a full rollback path:
```bash
# Restore all backed-up configs
cp -r ~/.config-bak/2026-07-03_120000/* ~/
```

## Future Considerations (not in scope for v1)

- Multi-distro support (Fedora, Arch, macOS)
- Per-host overrides (e.g., `home/.zshrc.local`)
- chezmoi/dotbot integration if template complexity grows
- CI to validate install.sh on a fresh container
