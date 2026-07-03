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

echo "  • Neovim (full tree)"
rm -rf "$REPO_ROOT/config/nvim"
cp -a ~/.config/nvim "$REPO_ROOT/config/nvim"
rm -rf "$REPO_ROOT/config/nvim/.git"

echo "  • OpenCode"
cp ~/.config/opencode/opencode.jsonc "$REPO_ROOT/config/opencode/opencode.jsonc"
for f in token-discipline stop-slop shell-policy rust-policy; do
  cp "$HOME/.config/opencode/$f.md" "$REPO_ROOT/config/opencode/$f.md"
done

echo "  • Yazi"
cp ~/.config/yazi/yazi.toml       "$REPO_ROOT/config/yazi/yazi.toml"
cp ~/.config/yazi/keymap.toml     "$REPO_ROOT/config/yazi/keymap.toml"
cp ~/.config/yazi/theme.toml      "$REPO_ROOT/config/yazi/theme.toml"
cp ~/.config/yazi/init.lua        "$REPO_ROOT/config/yazi/init.lua"
cp ~/.config/yazi/package.toml    "$REPO_ROOT/config/yazi/package.toml"

echo "  • .zshrc (→ .zshrc.tmpl)"
cp ~/.zshrc "$REPO_ROOT/home/.zshrc.tmpl"

echo "  • .tmux.conf";              cp ~/.tmux.conf "$REPO_ROOT/home/.tmux.conf"
echo "  • .gitconfig";              cp ~/.gitconfig "$REPO_ROOT/home/.gitconfig"
echo "  • .p10k.zsh (→ .p10k.zsh.tmpl)"; cp ~/.p10k.zsh "$REPO_ROOT/home/.p10k.zsh.tmpl"

# ── 2. Warn about untemplated machine-specific values ──
HOME_ESC="${HOME//\//\\/}"
UNTEMPLATED=$(grep -lRn "$HOME_ESC" "$REPO_ROOT/home/" "$REPO_ROOT/config/" 2>/dev/null || true)
if [ -n "$UNTEMPLATED" ]; then
  echo ""
  echo "  ${YELLOW:-}⚠ WARNING: These files still contain raw \$HOME paths:${RESET:-}"
  echo "$UNTEMPLATED" | sed "s|$REPO_ROOT/||" | sed 's/^/       /'
  echo "  Open them and replace new machine-specific values with {{VAR}} placeholders."
fi

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
