# Auth Bootstrap Phase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `bootstrap/05-auth.sh` — SSH keygen, keychain, Bitwarden CLI, and SSH config deploy — with auth helpers wired into `.zshrc`.

**Architecture:** New bootstrap phase following the patterns in `01-packages.sh`–`04-deploy.sh`. SSH config is a straight-copy file under `config/ssh/config`. Auth block added inline to `home/.zshrc.tmpl`.

**Tech Stack:** Bash, apt, npm, keychain, ssh-keygen

## Global Constraints

- Follow existing bootstrap patterns: `cd "$(dirname "$0")/.."`, `source bootstrap/lib.sh`, `set -euo pipefail`
- All operations must be idempotent — check before creating/installing
- Use `cmd_exists` for executable checks, `[ -f path ]` for file existence
- Use `backup_file` before overwriting existing configs
- Use `phase`, `log`, `success`, `warn` from `lib.sh`
- Non-fatal failures use `|| warn "..."` not `|| exit 1`

---

### Task 1: Create `config/ssh/config`

**Files:**
- Create: `config/ssh/config`
- Deploy: straight-copy to `~/.ssh/config` (no templating)

- [ ] **Write config/ssh/config**

Basic SSH client config with Ed25519 key, keepalive, and agent forwarding.

```ssh-config
Host *
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ForwardAgent yes
```

---

### Task 2: Create `bootstrap/05-auth.sh`

**Files:**
- Create: `bootstrap/05-auth.sh`

**Consumes:** `lib.sh`, `config/ssh/config`, installed `keychain` package

- [ ] **Write bootstrap/05-auth.sh**

Idempotent script with four phases:
1. SSH key generation (if `~/.ssh/id_ed25519` missing)
2. keychain installation via apt (if `cmd_exists keychain` fails)
3. SSH config deploy with backup (copy from repo to `~/.ssh/config`)
4. @bitwarden/cli via npm (if `cmd_exists bw` fails — non-fatal on npm failure)

---

### Task 3: Edit `home/.zshrc.tmpl`

**Files:**
- Modify: `home/.zshrc.tmpl` — append auth block after Fastfetch section (line ~260)

- [ ] **Append auth block to .zshrc.tmpl**

Add after the Fastfetch section: keychain eval, BW_SESSION caching, gh auth status warning.

---

### Task 4: Edit `install.sh`

**Files:**
- Modify: `install.sh:15` — add phase 5 line

- [ ] **Add phase 5/5 to install.sh**

Insert before the "complete" success message.

---

### Task 5: Edit `push-config.sh`

**Files:**
- Modify: `push-config.sh` — add SSH config capture in the "Capture current configs" section

- [ ] **Add SSH config capture to push-config.sh**

Add after the tmux config capture (line ~64). Straight `cp ~/.ssh/config config/ssh/config`.

---

### Task 6: Commit and push

- [ ] **Stage all changes, verify, commit, push**

```bash
git add -A && git status
git commit -m "feat: add bootstrap/05-auth.sh — SSH keys, keychain, Bitwarden CLI"
git push
```
