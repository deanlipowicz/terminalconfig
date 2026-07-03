#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source lib.sh

phase "Installing JetBrains Mono Nerd Font"

FONT_DIR="$HOME/.local/share/fonts"
FONT_NAME="JetBrainsMonoNerdFont"
RELEASE="v3.3.0"
URL="https://github.com/ryanoasis/nerd-fonts/releases/download/$RELEASE/JetBrainsMono.zip"

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
unzip -q -o "$TMP_ZIP" -d "$FONT_DIR" 2>/dev/null || warn "Extraction had warnings (non-fatal)"

rm -f "$FONT_DIR"/*.txt "$FONT_DIR"/*.md "$FONT_DIR"/readme* 2>/dev/null || true

log "Updating font cache"
fc-cache -f

if fc-list :family 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
  success "JetBrains Mono Nerd Font installed"
else
  warn "Font installation may not have succeeded — check $FONT_DIR"
fi
