#!/usr/bin/env bash
# push-config.sh — capture local configs, commit, and optionally push to GitHub.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

echo "━━ Syncing local configs back to repo ━━"
echo ""

# ── 1. Capture current configs ──
echo "  • Ghostty";               cp ~/.config/ghostty/config "$REPO_ROOT/config/ghostty/config"
echo "  • Harlequin";              cp ~/.config/harlequin/config.toml "$REPO_ROOT/config/harlequin/config.toml"

echo "  • Micro"
mkdir -p "$REPO_ROOT/config/micro/colorschemes"
cp ~/.config/micro/settings.json "$REPO_ROOT/config/micro/settings.json"
cp ~/.config/micro/colorschemes/catppuccin-mocha.micro "$REPO_ROOT/config/micro/colorschemes/catppuccin-mocha.micro"

echo "  • Neovim (full tree)"
rm -rf "$REPO_ROOT/config/nvim"
cp -a ~/.config/nvim "$REPO_ROOT/config/nvim"
rm -rf "$REPO_ROOT/config/nvim/.git"

echo "  • OpenCode"
cp ~/.config/opencode/opencode.jsonc "$REPO_ROOT/config/opencode/opencode.jsonc"
cp ~/.config/opencode/tui.json "$REPO_ROOT/config/opencode/tui.json"
for f in token-discipline stop-slop shell-policy rust-policy; do
  cp "$HOME/.config/opencode/$f.md" "$REPO_ROOT/config/opencode/$f.md"
done

echo "  • Yazi"
cp ~/.config/yazi/yazi.toml       "$REPO_ROOT/config/yazi/yazi.toml"
cp ~/.config/yazi/keymap.toml     "$REPO_ROOT/config/yazi/keymap.toml"
cp ~/.config/yazi/theme.toml      "$REPO_ROOT/config/yazi/theme.toml"
cp ~/.config/yazi/init.lua        "$REPO_ROOT/config/yazi/init.lua"
cp ~/.config/yazi/package.toml    "$REPO_ROOT/config/yazi/package.toml"

echo "  • Bat"
mkdir -p "$REPO_ROOT/config/bat/themes"
cp ~/.config/bat/config "$REPO_ROOT/config/bat/config"
cp ~/.config/bat/themes/Catppuccin\ Mocha.tmTheme "$REPO_ROOT/config/bat/themes/Catppuccin Mocha.tmTheme"

echo "  • Fastfetch"
mkdir -p "$REPO_ROOT/config/fastfetch/presets"
cp ~/.config/fastfetch/presets/catppuccin-mocha.jsonc "$REPO_ROOT/config/fastfetch/presets/catppuccin-mocha.jsonc"

echo "  • Btop"
mkdir -p "$REPO_ROOT/config/btop/themes"
cp ~/.config/btop/btop.conf "$REPO_ROOT/config/btop/btop.conf"
cp ~/.config/btop/themes/catppuccin_mocha.theme "$REPO_ROOT/config/btop/themes/catppuccin_mocha.theme"

echo "  • .zshrc (→ .zshrc.tmpl)"
cp ~/.zshrc "$REPO_ROOT/home/.zshrc.tmpl"

echo "  • .tmux.conf";              cp ~/.tmux.conf "$REPO_ROOT/home/.tmux.conf"
echo "  • .gitconfig";              cp ~/.gitconfig "$REPO_ROOT/home/.gitconfig"
echo "  • .p10k.zsh (→ .p10k.zsh.tmpl)"; cp ~/.p10k.zsh "$REPO_ROOT/home/.p10k.zsh.tmpl"

# ── 2. Re-template machine-specific values ──
# Convert known local paths back to {{VAR}} placeholders so the repo stays portable.

# .zshrc.tmpl
sed -i \
  -e "s|CMDSTAN_HOME=\"\$HOME/\.cmdstan/cmdstan-2\.[0-9.]*\"|CMDSTAN_HOME=\"{{CMDSTAN_HOME}}\"|" \
  -e "s|HIP_VISIBLE_DEVICES=\"[0-9]*\"|HIP_VISIBLE_DEVICES=\"{{HIP_VISIBLE_DEVICES}}\"|" \
  -e "s|HSA_OVERRIDE_GFX_VERSION=\"[0-9.]*\"|HSA_OVERRIDE_GFX_VERSION=\"{{HSA_OVERRIDE_GFX_VERSION}}\"|" \
  -e "s|HIP_FORCE_DEV_KERNARG=\"[0-9]*\"|HIP_FORCE_DEV_KERNARG=\"{{HIP_FORCE_DEV_KERNARG}}\"|" \
  -e "s|\$HOME/\.opencode/bin|{{OPENCODE_PATH}}|g" \
  "$REPO_ROOT/home/.zshrc.tmpl" 2>/dev/null || true
# Ensure template header exists
if ! head -1 "$REPO_ROOT/home/.zshrc.tmpl" | grep -q "Template variables"; then
  sed -i '1i# Template variables:\n#   CMDSTAN_HOME  path to CmdStan (default: $HOME/.cmdstan/cmdstan-2.39.0)\n#   HIP_VISIBLE_DEVICES  GPU devices for HIP (default: 0)\n#   HSA_OVERRIDE_GFX_VERSION  GFX version override (default: 11.0.0)\n#   HIP_FORCE_DEV_KERNARG  force kernel args (default: 1)\n#   OPENCODE_PATH  path to opencode binary dir (default: $HOME/.opencode/bin)\n' "$REPO_ROOT/home/.zshrc.tmpl"
fi

# options.lua
sed -i \
  "s|python3_host_prog = \"/.*\"|python3_host_prog = \"{{PYTHON_HOST_PROG}}\"|" \
  "$REPO_ROOT/config/nvim/lua/config/options.lua" 2>/dev/null || true

# opencode.jsonc — instruction paths
sed -i \
  -e "s|\"$HOME/\.config/opencode/|\"{{OPENCODE_CONFIG_DIR}}/|g" \
  -e "s|\"$HOME/terminal-applications\"|\"{{TERMINAL_APPLICATIONS_PATH}}\"|" \
  "$REPO_ROOT/config/opencode/opencode.jsonc" 2>/dev/null || true

# ── 3. Commit ──
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
git add -A
if git diff --cached --quiet; then
  echo ""
  echo "  Nothing changed — no commit needed."
  exit 0
fi

echo ""
echo "  Changes staged:"
git diff --stat --cached | sed 's/^/    /'
echo ""

git commit -m "sync: $TIMESTAMP" --quiet
COMMIT_SHA=$(git rev-parse --short HEAD)
echo "  ✓ Committed as $COMMIT_SHA"

# ── 4. Optional push ──
REMOTE=$(git remote -v 2>/dev/null | head -1 || true)
if [ -z "$REMOTE" ]; then
  echo "  No remote configured — commit saved locally."
  exit 0
fi

echo ""
echo "  Push to GitHub? (y/N): "
read -r REPLY </dev/tty
if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
  git push
  echo "  ✓ Pushed."
else
  echo "  Skipped push. Run: git push"
fi
