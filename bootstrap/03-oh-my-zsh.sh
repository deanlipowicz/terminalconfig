#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source lib.sh

phase "Installing Oh My Zsh"
ZSH_DIR="$HOME/.oh-my-zsh"
if [ -d "$ZSH_DIR" ]; then
  log "Oh My Zsh already installed at $ZSH_DIR"
else
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

if [ "$SHELL" != "$(which zsh)" ]; then
  log "Changing default shell to zsh (may prompt for password)"
  chsh -s "$(which zsh)" "$USER" 2>/dev/null || warn "Could not change shell — run: chsh -s $(which zsh)"
fi

success "Oh My Zsh setup complete"
