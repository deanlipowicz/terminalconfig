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
echo ""
