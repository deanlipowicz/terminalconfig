#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source bootstrap/lib.sh

REPO_ROOT="$(pwd)"

phase "Generating Ed25519 SSH key"
if [ -f "$HOME/.ssh/id_ed25519" ]; then
  log "SSH key already exists at ~/.ssh/id_ed25519"
else
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "$USER@$(hostname)-$(date +%Y-%m-%d)"
  success "Ed25519 SSH key generated"
fi

phase "Installing keychain (SSH agent manager)"
if cmd_exists keychain; then
  log "keychain already installed"
else
  sudo apt install -y keychain
  success "keychain installed"
fi

phase "Deploying ~/.ssh/config"
mkdir -p "$HOME/.ssh"
backup_file "$HOME/.ssh/config"
cp "$REPO_ROOT/config/ssh/config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"
success "Deployed ~/.ssh/config from config/ssh/config"

phase "Installing @bitwarden/cli"
if cmd_exists bw; then
  log "@bitwarden/cli already installed"
elif cmd_exists npm; then
  npm install -g @bitwarden/cli 2>/dev/null || warn "@bitwarden/cli install failed (non-fatal)"
  if cmd_exists bw; then
    success "@bitwarden/cli installed"
  fi
else
  warn "npm not found — skipping @bitwarden/cli install (non-fatal)"
fi

echo ""
success "Auth bootstrap complete"
