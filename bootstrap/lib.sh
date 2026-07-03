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

readonly BACKUP_TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"

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
  local bak_dir="$bak_root/$BACKUP_TIMESTAMP"
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
