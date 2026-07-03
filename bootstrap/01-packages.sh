#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source lib.sh

phase "Installing APT packages"
sudo apt update

APT_PKGS=(
  zsh tmux neovim ghostty yazi
  eza fdfind ripgrep bat
  git curl wget xclip unzip
  fzf jq yq zoxide
  python3 python3-pip python3-venv python3-pygments
  build-essential pkg-config libssl-dev
)

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
  binary="$(echo "$tool" | sed 's/^git-delta$/delta/; s/^cargo-update$/cargo-install-update/')"
  if cmd_exists "$binary"; then
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
  warn "npm not found — installing Node.js via apt"
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
