#!/usr/bin/env bash
# push-config.sh — sync local config changes back into the repo.
# Run from the terminalconfig repo root after changing configs locally.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "━━ Syncing local configs back to repo ━━"

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
for f in token-discipline stop-slop shell-policy rust-policy; do
  cp "$HOME/.config/opencode/$f.md" "$REPO_ROOT/config/opencode/$f.md"
done

echo "  • Yazi"
cp ~/.config/yazi/yazi.toml "$REPO_ROOT/config/yazi/yazi.toml"
cp ~/.config/yazi/keymap.toml "$REPO_ROOT/config/yazi/keymap.toml"
cp ~/.config/yazi/theme.toml "$REPO_ROOT/config/yazi/theme.toml"
cp ~/.config/yazi/init.lua "$REPO_ROOT/config/yazi/init.lua"
cp ~/.config/yazi/package.toml "$REPO_ROOT/config/yazi/package.toml"

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
