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

declare -a TARGETS

while IFS= read -r -d '' f; do
  rel="${f#config/}"
  TARGETS+=("$HOME/.config/$rel")
done < <(find config -type f -print0)

while IFS= read -r -d '' f; do
  basename="$(basename "$f")"
  basename="${basename%.tmpl}"
  TARGETS+=("$HOME/$basename")
done < <(find home -type f -print0)

for target in "${TARGETS[@]}"; do
  backup_file "$target"
done

phase "Deploying config files"

while IFS= read -r -d '' f; do
  rel="${f#config/}"
  target="$HOME/.config/$rel"
  mkdir -p "$(dirname "$target")"

  if [[ "$f" == *.tmpl ]]; then
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
        ln -sf "$REPO_ROOT/$f" "$target"
        ;;
    esac
  else
    ln -sf "$REPO_ROOT/$f" "$target"
  fi
  success "Deployed $rel"
done < <(find config -type f -print0)

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

latest_bak=$(ls -dt "$HOME/.config-bak"/*/ 2>/dev/null | head -1)
if [ -n "$latest_bak" ]; then
  log "Backup: $latest_bak"
fi
