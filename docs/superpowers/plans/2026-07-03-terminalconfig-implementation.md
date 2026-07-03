# terminalconfig Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Populate the `terminalconfig` GitHub repo with all local config files, a modular bootstrap system that installs every dependency and deploys configs on any Linux machine, and a push utility to sync local changes back.

**Architecture:** Single-bootstrap-directory layout under `terminalconfig/`. The `install.sh` entry point orchestrates four idempotent bootstrap phases (packages, fonts, oh-my-zsh, deploy). Machine-specific values use `{{VAR}}` template variables rendered at deploy time. A `push-config.sh` utility inverts the deploy step to sync local changes back into the repo.

**Tech Stack:** Bash (POSIX-ish, with bashisms for arrays/`source`), apt/cargo/pipx/uv/npm for package management, git for version control.

## Global Constraints

- All scripts must be idempotent (safe to re-run)
- All scripts run on Ubuntu 24.04+ Linux (future distro support is out of scope)
- Existing configs are backed up before overwrite to `~/.config-bak/YYYY-MM-DD_HHMMSS/`
- Template variables use `{{VAR_NAME}}` syntax, rendered by `04-deploy.sh`
- nvim config is included as plain files (no submodule)
- The repo must contain a `push-config.sh` that copies local configs back into the repo structure

---

### Task 1: Repo scaffolding + shared library

**Files:**
- Create: `terminalconfig/bootstrap/lib.sh`
- Create: `terminalconfig/.gitignore`

**Interfaces:**
- Consumes: nothing
- Produces: `lib.sh` — sourced by all bootstrap phases; provides `log()`, `phase()`, `success()`, `warn()`, `error()`, `backup_file()`, `render_template()`, `os_detect()`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p /home/workstation/terminalconfig/{bootstrap,config,home,docs/superpowers/specs,docs/superpowers/plans}
```

- [ ] **Step 2: Create `.gitignore`**

```bash
cat > /home/workstation/terminalconfig/.gitignore << 'GITIGNORE'
*.swp
*.swo
*~
.DS_Store
GITIGNORE
```

- [ ] **Step 3: Write `bootstrap/lib.sh`**

```bash
cat > /home/workstation/terminalconfig/bootstrap/lib.sh << 'LIB'
#!/usr/bin/env bash
# Shared helpers for terminalconfig bootstrap phases.
# Source this file, do not execute directly.
set -euo pipefail

# ── Colors ──
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"

log()   { echo -e "  ${BLUE}•${RESET} $*"; }
phase() { echo -e "\n${BOLD}${CYAN}══ $*${RESET}"; }
success() { echo -e "  ${GREEN}✓${RESET} $*"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET} $*"; }
error() { echo -e "  ${RED}✗${RESET} $*"; }

# ── OS Detection ──
os_detect() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  else
    echo "linux"
  fi
}

# ── Backup ──
# backup_file TARGET
#   Copies TARGET to ~/.config-bak/TIMESTAMP/RELATIVE_PATH if TARGET exists.
#   Returns 0 if backed up, 0 if not found (no error), 1 on failure.
backup_file() {
  local target="$1"
  [ -e "$target" ] || return 0

  local bak_root="$HOME/.config-bak"
  local timestamp
  timestamp="$(date +%Y-%m-%d_%H%M%S)"
  local bak_dir="$bak_root/$timestamp"
  mkdir -p "$bak_dir"

  # Strip $HOME prefix for relative path in backup
  local rel="${target#$HOME/}"
  local bak_target="$bak_dir/$rel"
  mkdir -p "$(dirname "$bak_target")"

  cp -a "$target" "$bak_target" || return 1
  log "Backed up $target → $bak_target"
  return 0
}

# ── Template Rendering ──
# render_template SRC DEST [VAR=val ...]
#   Reads SRC, replaces {{VAR}} with provided values, writes DEST.
render_template() {
  local src="$1"
  local dest="$2"
  shift 2

  local content
  content="$(cat "$src")"

  local var val
  for pair in "$@"; do
    var="${pair%%=*}"
    val="${pair#*=}"
    content="${content//\{\{$var\}\}/$val}"
  done

  echo "$content" > "$dest"
  success "Rendered template $src → $dest"
}

# ── Command Check ──
cmd_exists() { command -v "$1" &>/dev/null; }
LIB
```

- [ ] **Step 4: Verify `lib.sh` is syntactically valid**

Run: `bash -n /home/workstation/terminalconfig/bootstrap/lib.sh`
Expected: no output (exit code 0)

- [ ] **Step 5: Commit**

```bash
cd /home/workstation/terminalconfig
git init
git add bootstrap/lib.sh .gitignore
git commit -m "init: repo scaffolding and shared bootstrap library"
```

---

### Task 2: Pull config files from local machine into repo

**Files:**
- Create: `terminalconfig/config/ghostty/config`
- Create: `terminalconfig/config/harlequin/config.toml`
- Create: `terminalconfig/config/nvim/` (full tree)
- Create: `terminalconfig/config/opencode/opencode.jsonc`
- Create: `terminalconfig/config/opencode/token-discipline.md`
- Create: `terminalconfig/config/opencode/stop-slop.md`
- Create: `terminalconfig/config/opencode/shell-policy.md`
- Create: `terminalconfig/config/opencode/rust-policy.md`
- Create: `terminalconfig/config/yazi/yazi.toml`
- Create: `terminalconfig/config/yazi/keymap.toml`
- Create: `terminalconfig/config/yazi/theme.toml`
- Create: `terminalconfig/config/yazi/init.lua`
- Create: `terminalconfig/config/yazi/package.toml`
- Create: `terminalconfig/config/yazi/flavors/` and `config/yazi/plugins/` directories
- Create: `terminalconfig/home/.zshrc` (will be made .tmpl in Task 6)
- Create: `terminalconfig/home/.tmux.conf`
- Create: `terminalconfig/home/.gitconfig`
- Create: `terminalconfig/home/.p10k.zsh` (will be made .tmpl in Task 6)

- [ ] **Step 1: Copy Ghostty config**

```bash
cp ~/.config/ghostty/config /home/workstation/terminalconfig/config/ghostty/config
```

- [ ] **Step 2: Copy Harlequin config**

```bash
cp ~/.config/harlequin/config.toml /home/workstation/terminalconfig/config/harlequin/config.toml
```

- [ ] **Step 3: Copy Neovim config (full tree, preserving .gitignore)**

```bash
rm -rf /home/workstation/terminalconfig/config/nvim
cp -a ~/.config/nvim /home/workstation/terminalconfig/config/nvim
rm -rf /home/workstation/terminalconfig/config/nvim/.git
```

- [ ] **Step 4: Copy OpenCode config and instruction files**

```bash
cp ~/.config/opencode/opencode.jsonc /home/workstation/terminalconfig/config/opencode/opencode.jsonc
cp ~/.config/opencode/token-discipline.md /home/workstation/terminalconfig/config/opencode/token-discipline.md
cp ~/.config/opencode/stop-slop.md /home/workstation/terminalconfig/config/opencode/stop-slop.md
cp ~/.config/opencode/shell-policy.md /home/workstation/terminalconfig/config/opencode/shell-policy.md
cp ~/.config/opencode/rust-policy.md /home/workstation/terminalconfig/config/opencode/rust-policy.md
```

- [ ] **Step 5: Copy Yazi config and plugin tree**

```bash
cp ~/.config/yazi/yazi.toml /home/workstation/terminalconfig/config/yazi/yazi.toml
cp ~/.config/yazi/keymap.toml /home/workstation/terminalconfig/config/yazi/keymap.toml
cp ~/.config/yazi/theme.toml /home/workstation/terminalconfig/config/yazi/theme.toml
cp ~/.config/yazi/init.lua /home/workstation/terminalconfig/config/yazi/init.lua
cp ~/.config/yazi/package.toml /home/workstation/terminalconfig/config/yazi/package.toml
cp -a ~/.config/yazi/flavors /home/workstation/terminalconfig/config/yazi/flavors
cp -a ~/.config/yazi/plugins /home/workstation/terminalconfig/config/yazi/plugins
```

- [ ] **Step 6: Copy home dotfiles**

```bash
cp ~/.zshrc /home/workstation/terminalconfig/home/.zshrc
cp ~/.tmux.conf /home/workstation/terminalconfig/home/.tmux.conf
cp ~/.gitconfig /home/workstation/terminalconfig/home/.gitconfig
cp ~/.p10k.zsh /home/workstation/terminalconfig/home/.p10k.zsh
```

- [ ] **Step 7: Commit**

```bash
cd /home/workstation/terminalconfig
git add config/ home/
git commit -m "config: add all tool configs and home dotfiles"
```

---

### Task 3: Template machine-specific values

**Files:**
- Modify: `terminalconfig/home/.zshrc` → renamed to `.zshrc.tmpl` with `{{VAR}}` replacements
- Modify: `terminalconfig/home/.p10k.zsh` → renamed to `.p10k.zsh.tmpl` (no actual replacements needed currently, but prepared for future)
- Modify: `terminalconfig/config/nvim/lua/config/options.lua` — template `python3_host_prog`
- Modify: `terminalconfig/config/opencode/opencode.jsonc` — template instruction paths and reference path

- [ ] **Step 1: Rename .zshrc to .zshrc.tmpl and template values**

Replace machine-specific values in the file:
- `export CMDSTAN_HOME="$HOME/.cmdstan/cmdstan-2.39.0"` → `export CMDSTAN_HOME="{{CMDSTAN_HOME}}"`
- `export HIP_VISIBLE_DEVICES="0"` → `export HIP_VISIBLE_DEVICES="{{HIP_VISIBLE_DEVICES}}"`
- `export HSA_OVERRIDE_GFX_VERSION="11.0.0"` → `export HSA_OVERRIDE_GFX_VERSION="{{HSA_OVERRIDE_GFX_VERSION}}"`
- `export HIP_FORCE_DEV_KERNARG="1"` → `export HIP_FORCE_DEV_KERNARG="{{HIP_FORCE_DEV_KERNARG}}"`
- `export PATH=/home/workstation/.opencode/bin:$PATH` → `export PATH={{OPENCODE_PATH}}:$PATH`

```bash
mv /home/workstation/terminalconfig/home/.zshrc /home/workstation/terminalconfig/home/.zshrc.tmpl
```

Edit the file to replace:
- `"$HOME/.cmdstan/cmdstan-2.39.0"` → `"{{CMDSTAN_HOME}}"`
- `HIP_VISIBLE_DEVICES="0"` → `HIP_VISIBLE_DEVICES="{{HIP_VISIBLE_DEVICES}}"`
- `HSA_OVERRIDE_GFX_VERSION="11.0.0"` → `HSA_OVERRIDE_GFX_VERSION="{{HSA_OVERRIDE_GFX_VERSION}}"`
- `HIP_FORCE_DEV_KERNARG="1"` → `HIP_FORCE_DEV_KERNARG="{{HIP_FORCE_DEV_KERNARG}}"`
- `/home/workstation/.opencode/bin` → `{{OPENCODE_PATH}}`

Add a template header comment at the top:

```bash
# Template variables:
#   CMDSTAN_HOME  path to CmdStan (default: $HOME/.cmdstan/cmdstan-2.39.0)
#   HIP_VISIBLE_DEVICES  GPU devices for HIP (default: 0)
#   HSA_OVERRIDE_GFX_VERSION  GFX version override (default: 11.0.0)
#   HIP_FORCE_DEV_KERNARG  force kernel args (default: 1)
#   OPENCODE_PATH  path to opencode binary dir (default: $HOME/.opencode/bin)
```

- [ ] **Step 2: Rename .p10k.zsh to .p10k.zsh.tmpl**

```bash
mv /home/workstation/terminalconfig/home/.p10k.zsh /home/workstation/terminalconfig/home/.p10k.zsh.tmpl
```

Add template header:

```bash
# Template variables:
#   (none currently — file has no machine-specific paths)
```

- [ ] **Step 3: Template nvim options.lua**

Edit `config/nvim/lua/config/options.lua`:
Replace `"/home/workstation/.local/venvs/quarto-jupyter/bin/python"` → `"/usr/bin/python3"` (sensible default)

Add a comment:
```lua
-- Template variable: PYTHON_HOST_PROG  path to python3 for :python3 (default: /usr/bin/python3)
vim.g.python3_host_prog = "{{PYTHON_HOST_PROG}}"
```

- [ ] **Step 4: Template opencode.jsonc**

Edit `config/opencode/opencode.jsonc`:
Replace `/home/workstation/.config/opencode/` → `{{OPENCODE_CONFIG_DIR}}`
Replace `/home/workstation/terminal-applications` → `{{TERMINAL_APPLICATIONS_PATH}}`

The instruction paths should use the template variable:
```
"/home/workstation/.config/opencode/token-discipline.md"  →  "{{OPENCODE_CONFIG_DIR}}/token-discipline.md"
```

The reference path should be:
```
"path": "/home/workstation/terminal-applications"  →  "path": "{{TERMINAL_APPLICATIONS_PATH}}"
```

- [ ] **Step 5: Commit**

```bash
cd /home/workstation/terminalconfig
git add -A
git commit -m "config: template machine-specific values with {{VAR}} placeholders"
```

---

### Task 4: `bootstrap/01-packages.sh` — system dependency installation

**Files:**
- Create: `terminalconfig/bootstrap/01-packages.sh`

**Interfaces:**
- Consumes: `lib.sh` (sourced for helpers)
- Produces: Installed apt/cargo/pipx/uv/npm packages; exits 0 on success

- [ ] **Step 1: Write `01-packages.sh`**

```bash
cat > /home/workstation/terminalconfig/bootstrap/01-packages.sh << 'PACKAGES'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source lib.sh

phase "Installing APT packages"
# Ensure apt is up to date first
sudo apt update

# Core terminal tools
APT_PKGS=(
  zsh tmux neovim ghostty yazi
  eza fdfind ripgrep bat
  git curl wget xclip unzip
  fzf jq yq zoxide
  python3 python3-pip python3-venv python3-pygments
  build-essential pkg-config libssl-dev
)

# Install in one batch
sudo apt install -y "${APT_PKGS[@]}"
success "APT packages installed"

phase "Installing Rust toolchain (if missing)"
if ! cmd_exists rustc; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  success "Rust toolchain installed"
else
  log "Rust toolchain already present"
fi

phase "Installing Cargo tools"
export PATH="$HOME/.cargo/bin:$PATH"
CARGO_TOOLS=(git-delta cargo-update)
for tool in "${CARGO_TOOLS[@]}"; do
  if cmd_exists "$(echo "$tool" | sed 's/^git-delta$/delta/; s/^cargo-update$/cargo-install-update/')"; then
    log "$tool already installed, skipping"
  else
    cargo install "$tool"
    success "$tool installed"
  fi
done

phase "Installing pipx packages"
if ! cmd_exists pipx; then
  python3 -m pip install --user pipx
  python3 -m pipx ensurepath
fi
PIPX_PKGS=(harlequin)
for pkg in "${PIPX_PKGS[@]}"; do
  if pipx list 2>/dev/null | grep -q "$pkg"; then
    log "$pkg already installed, upgrading"
    pipx upgrade "$pkg" 2>/dev/null || true
  else
    pipx install "$pkg"
    success "$pkg installed"
  fi
done

phase "Installing uv tools"
if ! cmd_exists uv; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
UV_TOOLS=(pyright ruff cmake-language-server pre-commit)
for tool in "${UV_TOOLS[@]}"; do
  if uv tool list 2>/dev/null | grep -q "$tool"; then
    uv tool upgrade "$tool" 2>/dev/null || true
  else
    uv tool install "$tool" || warn "uv tool $tool install failed (non-fatal)"
  fi
done

phase "Installing npm global tools"
if ! cmd_exists npm; then
  warn "npm not found — installing Node.js via nvm or apt"
  # Fallback: try apt
  sudo apt install -y nodejs npm 2>/dev/null || warn "nodejs/npm install failed (non-fatal)"
fi
if cmd_exists npm; then
  NPM_PKGS=(
    bash-language-server
    yaml-language-server
    typescript typescript-language-server
    vscode-langservers-extracted
    prettier
    sql-language-server
    tree-sitter-cli
  )
  for pkg in "${NPM_PKGS[@]}"; do
    npm install -g "$pkg" 2>/dev/null || warn "npm $pkg install failed (non-fatal)"
  done
  success "npm global tools installed"
fi

success "Package installation complete"
PACKAGES
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n /home/workstation/terminalconfig/bootstrap/01-packages.sh`
Expected: no output (exit code 0)

- [ ] **Step 3: Commit**

```bash
cd /home/workstation/terminalconfig
git add bootstrap/01-packages.sh
git commit -m "feat: add system package installation phase"
```

---

### Task 5: `bootstrap/02-fonts.sh` — Nerd Font installation

**Files:**
- Create: `terminalconfig/bootstrap/02-fonts.sh`

- [ ] **Step 1: Write `02-fonts.sh`**

```bash
cat > /home/workstation/terminalconfig/bootstrap/02-fonts.sh << 'FONTS'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source lib.sh

phase "Installing JetBrains Mono Nerd Font"

FONT_DIR="$HOME/.local/share/fonts"
FONT_NAME="JetBrainsMonoNerdFont"
RELEASE="v3.3.0"
URL="https://github.com/ryanoasis/nerd-fonts/releases/download/$RELEASE/JetBrainsMono.zip"

# Check if already installed
if fc-list :family 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
  success "JetBrains Mono Nerd Font already installed"
  exit 0
fi

mkdir -p "$FONT_DIR"

log "Downloading JetBrains Mono Nerd Font from $URL"
TMP_ZIP="$(mktemp /tmp/jetbrains-nerd-font-XXXXXX.zip)"
trap 'rm -f "$TMP_ZIP"' EXIT

curl -fsSL "$URL" -o "$TMP_ZIP"

log "Extracting to $FONT_DIR"
unzip -q -o "$TMP_ZIP" -d "$FONT_DIR" 2>/dev/null || {
  warn "Extraction had warnings (non-fatal)"
}

# Remove Windows and readme files
rm -f "$FONT_DIR"/*.txt "$FONT_DIR"/*.md "$FONT_DIR"/readme* 2>/dev/null || true

log "Updating font cache"
fc-cache -f

if fc-list :family 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
  success "JetBrains Mono Nerd Font installed"
else
  warn "Font installation may not have succeeded — check $FONT_DIR"
fi
FONTS
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n /home/workstation/terminalconfig/bootstrap/02-fonts.sh`
Expected: no output (exit code 0)

- [ ] **Step 3: Commit**

```bash
cd /home/workstation/terminalconfig
git add bootstrap/02-fonts.sh
git commit -m "feat: add Nerd Font installation phase"
```

---

### Task 6: `bootstrap/03-oh-my-zsh.sh` — Zsh framework setup

**Files:**
- Create: `terminalconfig/bootstrap/03-oh-my-zsh.sh`

- [ ] **Step 1: Write `03-oh-my-zsh.sh`**

```bash
cat > /home/workstation/terminalconfig/bootstrap/03-oh-my-zsh.sh << 'OHMYZSH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source lib.sh

phase "Installing Oh My Zsh"
ZSH_DIR="$HOME/.oh-my-zsh"
if [ -d "$ZSH_DIR" ]; then
  log "Oh My Zsh already installed at $ZSH_DIR"
else
  # Run the official installer non-interactively
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  success "Oh My Zsh installed"
fi

phase "Installing Powerlevel10k theme"
P10K_DIR="${ZSH_DIR}/custom/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
  log "Powerlevel10k already installed"
else
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  success "Powerlevel10k installed"
fi

phase "Installing Zsh plugins"
PLUGIN_DIR="${ZSH_DIR}/custom/plugins"
mkdir -p "$PLUGIN_DIR"

install_plugin() {
  local name="$1"
  local url="$2"
  local dir="$PLUGIN_DIR/$name"
  if [ -d "$dir" ]; then
    log "Plugin $name already installed"
  else
    git clone --depth=1 "$url" "$dir"
    success "Plugin $name installed"
  fi
}

install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

# Ensure zsh is the default shell (if not already)
if [ "$SHELL" != "$(which zsh)" ]; then
  log "Changing default shell to zsh (may prompt for password)"
  chsh -s "$(which zsh)" "$USER" 2>/dev/null || warn "Could not change shell — run: chsh -s $(which zsh)"
fi

success "Oh My Zsh setup complete"
OHMYZSH
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n /home/workstation/terminalconfig/bootstrap/03-oh-my-zsh.sh`
Expected: no output (exit code 0)

- [ ] **Step 3: Commit**

```bash
cd /home/workstation/terminalconfig
git add bootstrap/03-oh-my-zsh.sh
git commit -m "feat: add oh-my-zsh + p10k + plugins installation phase"
```

---

### Task 7: `bootstrap/04-deploy.sh` — config backup, template render, and deployment

**Files:**
- Create: `terminalconfig/bootstrap/04-deploy.sh`

**Interfaces:**
- Consumes: `lib.sh` (for backup_file, render_template), `config/` and `home/` directories
- Produces: Symlinks from repo files → target locations, backup of originals in `~/.config-bak/`

- [ ] **Step 1: Write `04-deploy.sh`**

```bash
cat > /home/workstation/terminalconfig/bootstrap/04-deploy.sh << 'DEPLOY'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source bootstrap/lib.sh

REPO_ROOT="$(pwd)"

# ── Default template values ──
: "${PYTHON_HOST_PROG:=/usr/bin/python3}"
: "${OPENCODE_CONFIG_DIR:=$HOME/.config/opencode}"
: "${TERMINAL_APPLICATIONS_PATH:=$HOME/terminal-applications}"
: "${CMDSTAN_HOME:=$HOME/.cmdstan/cmdstan-2.39.0}"
: "${HIP_VISIBLE_DEVICES:=0}"
: "${HSA_OVERRIDE_GFX_VERSION:=11.0.0}"
: "${HIP_FORCE_DEV_KERNARG:=1}"
: "${OPENCODE_PATH:=$HOME/.opencode/bin}"

phase "Backing up existing configs"

# Collect all target paths before backing up
declare -a TARGETS

# config/ → ~/.config/<tool>/
while IFS= read -r -d '' f; do
  rel="${f#config/}"
  tool="${rel%%/*}"
  filepath="${rel#*/}"
  TARGETS+=("$HOME/.config/$rel")
done < <(find config -type f -print0)

# home/ → ~/.<name> (strip .tmpl suffix)
while IFS= read -r -d '' f; do
  basename="$(basename "$f")"
  basename="${basename%.tmpl}"
  TARGETS+=("$HOME/$basename")
done < <(find home -type f -print0)

# Backup each target
for target in "${TARGETS[@]}"; do
  backup_file "$target"
done

phase "Deploying config files"

# Deploy config/ files
while IFS= read -r -d '' f; do
  rel="${f#config/}"
  target="$HOME/.config/$rel"

  mkdir -p "$(dirname "$target")"

  # Handle .tmpl files in config/
  if [[ "$f" == *.tmpl ]]; then
    # Determine template variables from filename prefix
    case "$f" in
      */nvim/*)
        render_template "$REPO_ROOT/$f" "$target" "PYTHON_HOST_PROG=$PYTHON_HOST_PROG"
        ;;
      */opencode/*)
        render_template "$REPO_ROOT/$f" "$target" \
          "OPENCODE_CONFIG_DIR=$OPENCODE_CONFIG_DIR" \
          "TERMINAL_APPLICATIONS_PATH=$TERMINAL_APPLICATIONS_PATH"
        ;;
      *)
        # Generic: just symlink as-is (no template rendering)
        ln -sf "$REPO_ROOT/$f" "$target"
        ;;
    esac
  else
    ln -sf "$REPO_ROOT/$f" "$target"
  fi

  success "Deployed $rel"
done < <(find config -type f -print0)

# Deploy home/ files
while IFS= read -r -d '' f; do
  basename="$(basename "$f")"
  basename="${basename%.tmpl}"
  target="$HOME/$basename"

  if [[ "$f" == *.tmpl ]]; then
    case "$basename" in
      .zshrc)
        render_template "$REPO_ROOT/$f" "$target" \
          "CMDSTAN_HOME=$CMDSTAN_HOME" \
          "HIP_VISIBLE_DEVICES=$HIP_VISIBLE_DEVICES" \
          "HSA_OVERRIDE_GFX_VERSION=$HSA_OVERRIDE_GFX_VERSION" \
          "HIP_FORCE_DEV_KERNARG=$HIP_FORCE_DEV_KERNARG" \
          "OPENCODE_PATH=$OPENCODE_PATH"
        ;;
      .p10k.zsh)
        render_template "$REPO_ROOT/$f" "$target"
        ;;
      *)
        render_template "$REPO_ROOT/$f" "$target"
        ;;
    esac
  else
    ln -sf "$REPO_ROOT/$f" "$target"
  fi

  success "Deployed $basename"
done < <(find home -type f -print0)

echo ""
success "All configs deployed. Backups in ~/.config-bak/"

# Print backup location
latest_bak=$(ls -dt "$HOME/.config-bak"/*/ 2>/dev/null | head -1)
if [ -n "$latest_bak" ]; then
  log "Backup: $latest_bak"
fi
DEPLOY
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n /home/workstation/terminalconfig/bootstrap/04-deploy.sh`
Expected: no output (exit code 0)

- [ ] **Step 3: Commit**

```bash
cd /home/workstation/terminalconfig
git add bootstrap/04-deploy.sh
git commit -m "feat: add config deployment phase with backup and template rendering"
```

---

### Task 8: `install.sh` entry point + `README.md`

**Files:**
- Create: `terminalconfig/install.sh`
- Create: `terminalconfig/README.md`

- [ ] **Step 1: Write `install.sh`**

```bash
cat > /home/workstation/terminalconfig/install.sh << 'INSTALL'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source bootstrap/lib.sh

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║    terminalconfig — Bootstrap        ║${RESET}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════╝${RESET}"
echo ""

phase "1/4  System packages & language tools"    && bootstrap/01-packages.sh
phase "2/4  Nerd Fonts"                           && bootstrap/02-fonts.sh
phase "3/4  Oh My Zsh + plugins"                  && bootstrap/03-oh-my-zsh.sh
phase "4/4  Deploy configs (backup + symlink)"    && bootstrap/04-deploy.sh

echo ""
success "terminalconfig bootstrap complete!"
echo ""
echo "  ${YELLOW}→${RESET} Restart your terminal or run: ${BOLD}exec zsh${RESET}"
echo "  ${YELLOW}→${RESET} To restore backups:  cp -r ~/.config-bak/$(date +%Y-%m-%d)*/* ~/"
echo ""
INSTALL
chmod +x /home/workstation/terminalconfig/install.sh
```

- [ ] **Step 2: Write `README.md`**

```bash
cat > /home/workstation/terminalconfig/README.md << 'README'
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
README
```

- [ ] **Step 3: Verify syntax**

Run: `bash -n /home/workstation/terminalconfig/install.sh`
Expected: no output (exit code 0)

- [ ] **Step 4: Commit**

```bash
cd /home/workstation/terminalconfig
git add install.sh README.md
git commit -m "feat: add install entry point and README"
```

---

### Task 9: `push-config.sh` — sync local changes back to repo

**Files:**
- Create: `terminalconfig/push-config.sh`

- [ ] **Step 1: Write `push-config.sh`**

```bash
cat > /home/workstation/terminalconfig/push-config.sh << 'PUSH'
#!/usr/bin/env bash
# push-config.sh — sync local config changes back into the repo.
# Run from the terminalconfig repo root after changing configs locally.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "━━ Syncing local configs back to repo ━━"

# ── config/ ← ~/.config/<tool>/ ──
echo "  • Ghostty"
cp ~/.config/ghostty/config "$REPO_ROOT/config/ghostty/config"

echo "  • Harlequin"
cp ~/.config/harlequin/config.toml "$REPO_ROOT/config/harlequin/config.toml"

echo "  • Neovim (full tree)"
rm -rf "$REPO_ROOT/config/nvim"
cp -a ~/.config/nvim "$REPO_ROOT/config/nvim"
rm -rf "$REPO_ROOT/config/nvim/.git"

echo "  • OpenCode"
cp ~/.config/opencode/opencode.jsonc "$REPO_ROOT/config/opencode/opencode.jsonc"
# Instruction files (non-templated copies)
for f in token-discipline stop-slop shell-policy rust-policy; do
  cp "$HOME/.config/opencode/$f.md" "$REPO_ROOT/config/opencode/$f.md"
done

echo "  • Yazi"
cp ~/.config/yazi/yazi.toml "$REPO_ROOT/config/yazi/yazi.toml"
cp ~/.config/yazi/keymap.toml "$REPO_ROOT/config/yazi/keymap.toml"
cp ~/.config/yazi/theme.toml "$REPO_ROOT/config/yazi/theme.toml"
cp ~/.config/yazi/init.lua "$REPO_ROOT/config/yazi/init.lua"
cp ~/.config/yazi/package.toml "$REPO_ROOT/config/yazi/package.toml"

# ── home/ ← ~/.* ──
echo "  • .zshrc (as .zshrc.tmpl — re-template before commit)"
cp ~/.zshrc "$REPO_ROOT/home/.zshrc.tmpl"

echo "  • .tmux.conf"
cp ~/.tmux.conf "$REPO_ROOT/home/.tmux.conf"

echo "  • .gitconfig"
cp ~/.gitconfig "$REPO_ROOT/home/.gitconfig"

echo "  • .p10k.zsh (as .p10k.zsh.tmpl)"
cp ~/.p10k.zsh "$REPO_ROOT/home/.p10k.zsh.tmpl"

echo ""
echo "✓ Configs synced. Next steps:"
echo "  1. Review:  git diff"
echo "  2. Re-template any new machine-specific values in .tmpl files"
echo "  3. Commit:  git add -A && git commit -m \"sync: ...\" && git push"
PUSH
chmod +x /home/workstation/terminalconfig/push-config.sh
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n /home/workstation/terminalconfig/push-config.sh`
Expected: no output (exit code 0)

- [ ] **Step 3: Commit**

```bash
cd /home/workstation/terminalconfig
git add push-config.sh
git commit -m "feat: add push-config utility to sync local changes back to repo"
```

---

### Task 10: Git push to GitHub

**Files:**
- Modify: `terminalconfig/` — set remote and push

- [ ] **Step 1: Add remote and push**

```bash
cd /home/workstation/terminalconfig
git remote add origin https://github.com/deanlipowicz/terminalconfig.git
git branch -M main
git push -u origin main
```

- [ ] **Step 2: Verify remote is up to date**

```bash
cd /home/workstation/terminalconfig
git log --oneline -5
```

---

## Self-Review Checklist (run after writing)

**1. Spec coverage:**
- [x] Repo layout with config/ and home/ → Tasks 1-2
- [x] Four bootstrap phases → Tasks 4-7
- [x] Template system for machine-specific values → Task 3 + Task 7
- [x] Backup strategy (timestamped .config-bak/) → Task 7 (in lib.sh + 04-deploy.sh)
- [x] Install entry point → Task 8
- [x] Push utility → Task 9
- [x] Override semantics → README (Task 8) + deploy behavior (Task 7)

**2. Placeholder scan:** No TBD, TODO, or "implement later" remains.

**3. Type consistency:** Template variable names match across Task 3 (definitions in .tmpl files) and Task 7 (render_template calls). Variable names: `PYTHON_HOST_PROG`, `OPENCODE_CONFIG_DIR`, `TERMINAL_APPLICATIONS_PATH`, `CMDSTAN_HOME`, `HIP_VISIBLE_DEVICES`, `HSA_OVERRIDE_GFX_VERSION`, `HIP_FORCE_DEV_KERNARG`, `OPENCODE_PATH`.
