# Auth Bootstrap Phase — Design Spec

## Summary

Add `bootstrap/05-auth.sh` — a fifth bootstrap phase that sets up SSH keys, SSH
agent (keychain), Bitwarden CLI, and GitHub auth plumbing, with the SSH config
captured as a portable file and auth helpers wired into `.zshrc`.

## Files

### New

- **`config/ssh/config`** — SSH client config deployed as a straight copy (no
  templating). Includes `IdentityFile ~/.ssh/id_ed25519`, `AddKeysToAgent yes`,
  and sensible defaults.
- **`bootstrap/05-auth.sh`** — idempotent bootstrap phase. Follows the
  `04-deploy.sh` pattern: `cd "$(dirname "$0")/.."`, `source bootstrap/lib.sh`,
  uses `cmd_exists`, `phase`, `log`, `success`, `warn`, `backup_file`.

### Modified

- **`home/.zshrc.tmpl`** — append auth block after the Fastfetch section:
  - keychain eval for SSH agent
  - `BW_SESSION` caching from `~/.bw_session`
  - `gh auth status` check warning
- **`install.sh`** — add phase line `5/5  Auth (SSH keys, keychain, Bitwarden)`
- **`push-config.sh`** — add `~/.ssh/config` capture to `config/ssh/config`

## `bootstrap/05-auth.sh` Steps

1. **Generate Ed25519 SSH key** if `~/.ssh/id_ed25519` does not exist
   (`ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""`)
2. **Install keychain** via `apt` if `cmd_exists keychain` fails
3. **Deploy SSH config**: `backup_file ~/.ssh/config`, then copy
   `config/ssh/config` to `~/.ssh/config`
4. **Install @bitwarden/cli** via `npm install -g @bitwarden/cli` if `bw` not
   found (non-fatal on failure, matching the npm pattern in `01-packages.sh`)

## `.zshrc.tmpl` Auth Block

```zsh
# -------- SSH Agent (keychain) --------
if command -v keychain &>/dev/null; then
  eval "$(keychain --eval --agents ssh --quick id_ed25519 2>/dev/null)"
fi

# -------- Bitwarden CLI --------
if command -v bw &>/dev/null && [[ -f ~/.bw_session ]]; then
  export BW_SESSION=$(cat ~/.bw_session 2>/dev/null)
fi

# -------- GitHub CLI auth check --------
if command -v gh &>/dev/null && ! gh auth status &>/dev/null 2>&1; then
  echo "  ! GitHub CLI not authenticated — run: gh auth login"
fi
```

## `push-config.sh` Addition

```bash
echo "  • SSH config"; cp ~/.ssh/config "$REPO_ROOT/config/ssh/config"
```

Placed in the "Capture current configs" section alongside the other tool
configs, before the templating section.

## `install.sh` Addition

```bash
phase "5/5  Auth (SSH keys, keychain, Bitwarden)" && bootstrap/05-auth.sh
```

Placed after the phase 4 line, before the "complete" summary.

## Existing Patterns Observed

| Aspect | Convention |
|--------|-----------|
| Shebang | `#!/usr/bin/env bash` |
| Safety | `set -euo pipefail` |
| Script dir | `cd "$(dirname "$0")"` or `cd "$(dirname "$0")/.."` |
| lib.sh | `source lib.sh` (same dir) or `source bootstrap/lib.sh` (from repo root) |
| Idempotency | `cmd_exists`, `[ -f path ]`, `[ -d path ]` guards |
| Output | `phase`, `log`, `success`, `warn` from `lib.sh` |
| Backup | `backup_file target` before overwriting |
| Non-fatal | `|| warn "..."` or `|| true` for recoverable failures |
