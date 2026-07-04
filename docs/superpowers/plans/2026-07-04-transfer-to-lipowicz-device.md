# Transfer terminal environment to lipowicz@100.102.244.16 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transfer the full terminalconfig bootstrap environment, terminal-applications reference docs, SSH identity, and GPG keys from this workstation to the Ubuntu device at 100.102.244.16 (user: lipowicz).

**Architecture:** Phased approach — pre-flight cleanup on workstation, manual SSH server setup on target, rsync/scp file transfers (SSH key, GPG keys, terminalconfig repo, terminal-applications docs), remote execution of install.sh bootstrap, and post-install manual config.

**Tech Stack:** bash, rsync, scp, ssh, git, apt (Ubuntu 24.04+)

## Global Constraints

- Target OS must be Ubuntu 24.04+ (apt packages like ghostty, yazi require recent repos)
- User must have sudo access on target (for apt installs and systemctl)
- User must have physical/console access to target for Phase 1 (SSH server not running)
- Workstation SSH key (~/.ssh/id_ed25519) is shared with target (same key for GitHub, etc.)
- install.sh pauses for sudo password — user must be present during Phase 3

---

### Task 1: Pre-flight — clean and push terminalconfig repo

**Files:**
- Modify: `~/terminalconfig/` (git working tree)

**What this does:** Commit any staged deletions and new spec/plan files, push to GitHub so the repo is in a clean state before rsync transfer.

- [ ] **Step 1: Review current repo status**

```bash
cd ~/terminalconfig && git status
```

Expected: should show staged deletions of old plan/spec docs and the new untracked spec/plan files. No unexpected changes.

- [ ] **Step 2: Stage and commit**

```bash
cd ~/terminalconfig
git add -A
git commit -m "cleanup: pre-transfer sync, add device transfer spec and plan"
```

- [ ] **Step 3: Push to GitHub**

```bash
git push
```

Expected: push succeeds to `git@github.com:deanlipowicz/terminalconfig.git`.

---

### Task 2: SSH server setup on target (MANUAL — requires physical/console access)

**What this does:** Install and enable OpenSSH server on the target machine. This step cannot be automated from the workstation because SSH isn't running yet.

- [ ] **Step 1: Verify target OS version**

On the target machine:

```bash
lsb_release -a
```

Expected: Ubuntu 24.04 or later. If earlier, some apt packages in 01-packages.sh may not be available.

- [ ] **Step 2: Install OpenSSH server**

On the target machine:

```bash
sudo apt update && sudo apt install -y openssh-server
```

- [ ] **Step 3: Enable and start SSH**

```bash
sudo systemctl enable --now ssh
sudo systemctl status ssh
```

Expected: `active (running)`.

- [ ] **Step 4: Test SSH connectivity from workstation**

Back on the workstation:

```bash
ssh -o ConnectTimeout=5 lipowicz@100.102.244.16 echo ok
```

Expected: prompts for lipowicz's password, then prints `ok`. If connection refused, verify SSH is running on target.

---

### Task 3: Copy SSH public key for passwordless auth

**What this does:** Install the workstation's SSH public key on the target so subsequent rsync and ssh commands don't need a password.

- [ ] **Step 1: Verify workstation SSH key exists**

```bash
ls -la ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```

Expected: both files exist. If not, generate with `ssh-keygen -t ed25519`.

- [ ] **Step 2: Copy public key to target**

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub lipowicz@100.102.244.16
```

Expected: prompts for lipowicz's password once, then reports key added.

- [ ] **Step 3: Verify passwordless SSH works**

```bash
ssh lipowicz@100.102.244.16 echo ok
```

Expected: prints `ok` without prompting for password.

---

### Task 4: Transfer SSH private key to target

**What this does:** Copy the workstation's SSH private key to the target so 05-auth.sh (which runs during install.sh) sees an existing key and skips generation. Also needed for git push/pull from the target.

- [ ] **Step 1: Ensure target ~/.ssh directory exists**

```bash
ssh lipowicz@100.102.244.16 mkdir -p ~/.ssh
```

- [ ] **Step 2: Copy private and public key**

```bash
scp ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub lipowicz@100.102.244.16:~/.ssh/
```

- [ ] **Step 3: Set correct permissions on target**

```bash
ssh lipowicz@100.102.244.16 chmod 600 ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```

---

### Task 5: Transfer GPG keys to target

**What this does:** Copy the GPG keyring so password-store (`pass`) works on the target without re-importing keys.

- [ ] **Step 1: Rsync GPG directory**

```bash
rsync -avz ~/.gnupg/ lipowicz@100.102.244.16:~/.gnupg/
```

- [ ] **Step 2: Verify GPG keys arrived**

```bash
ssh lipowicz@100.102.244.16 gpg --list-secret-keys --keyid-format=long
```

Expected: lists your GPG keys. Note the key ID for `pass init` later.

---

### Task 6: Transfer terminalconfig repo to target

**What this does:** Copy the full terminalconfig repo (including .git) so install.sh can run locally on the target and symlink configs into place.

- [ ] **Step 1: Rsync terminalconfig repo**

```bash
rsync -avz --exclude='.git/objects/pack/*.pack' ~/terminalconfig/ lipowicz@100.102.244.16:~/terminalconfig/
```

The `--exclude` skips large pack files (not needed on target; git can refetch if needed). Removes transfer overhead.

- [ ] **Step 2: Verify repo arrived**

```bash
ssh lipowicz@100.102.244.16 ls ~/terminalconfig/install.sh
```

Expected: file exists.

---

### Task 7: Transfer terminal-applications reference docs to target

**What this does:** Copy the terminal-applications directory so OpenCode config paths (which reference `~/terminal-applications/`) resolve correctly on the target.

- [ ] **Step 1: Rsync terminal-applications**

```bash
rsync -avz ~/terminal-applications/ lipowicz@100.102.244.16:~/terminal-applications/
```

- [ ] **Step 2: Verify docs arrived**

```bash
ssh lipowicz@100.102.244.16 ls ~/terminal-applications/terminal-env.md
```

Expected: file exists.

---

### Task 8: Run install.sh bootstrap on target (ATTENDED — requires sudo password)

**What this does:** Execute the terminalconfig bootstrap script on the target via SSH. The script will pause for sudo password during apt installs and npm global installs.

- [ ] **Step 1: SSH into target**

```bash
ssh lipowicz@100.102.244.16
```

- [ ] **Step 2: Run install.sh**

```bash
cd ~/terminalconfig
./install.sh
```

Expected output: the script runs 5 phases:

1. `1/4 System packages & language tools` — apt installs, Rust, Cargo tools, pipx, uv, npm globals
2. `2/4 Nerd Fonts` — JetBrains Mono Nerd Font
3. `3/4 Oh My Zsh + plugins` — Oh My Zsh, Powerlevel10k, plugins
4. `4/4 Deploy configs` — backs up existing configs, symlinks from repo
5. `5/5 Auth` — skips SSH key (exists), installs keychain + Bitwarden CLI

- [ ] **Step 3: Watch for sudo prompts**

The script will pause at `sudo apt install`. Enter the target's sudo password when prompted.

- [ ] **Step 4: Confirm bootstrap success**

Expected final output:

```
terminalconfig bootstrap complete!
→ Restart your terminal or run: exec zsh
```

---

### Task 9: Post-install — set git identity on target

**What this does:** The repo's `.gitconfig` only has delta/pager config. Git user.name and user.email must be set manually.

- [ ] **Step 1: Set git identity (still on target via SSH)**

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Replace with your actual name and email.

- [ ] **Step 2: Verify**

```bash
git config --global user.name
git config --global user.email
```

Expected: prints the values just set.

---

### Task 10: Post-install — restart shell and verify environment

**What this does:** Restart into zsh and run verification checks from the spec.

- [ ] **Step 1: Restart shell**

```bash
exec zsh
```

- [ ] **Step 2: Run verification checks**

```bash
echo $SHELL                          # should be /usr/bin/zsh
nvim --version | head -1             # Neovim installed
tmux -V                              # tmux installed
eza --version                        # eza installed
rg --version                         # ripgrep installed
bat --version                        # bat installed
ls -la ~/.zshrc                      # symlink to ~/terminalconfig/home/.zshrc
ls -la ~/.config/nvim                # symlink to ~/terminalconfig/config/nvim
```

All commands should succeed and show expected versions/paths.

- [ ] **Step 3: Optional credential setup**

Only if you use these on the target:

```bash
gh auth login        # GitHub CLI
doppler login        # Doppler secrets
pass init <gpg-id>   # password-store (use GPG key ID from Task 5 verification)
gpg --list-secret-keys --keyid-format=long  # get key ID for pass init
```

---

### Task 11: Commit and push plan

**Files:**
- Modify: `~/terminalconfig/` (git working tree)

- [ ] **Step 1: Commit the plan**

```bash
cd ~/terminalconfig
git add docs/superpowers/plans/2026-07-04-transfer-to-lipowicz-device.md
git commit -m "plan: transfer terminal environment to lipowicz device"
```

- [ ] **Step 2: Push**

```bash
git push
```

---

## Task Dependency Graph

```
Task 1 (pre-flight) ─────────────────────────────────────────────────────┐
                                                                          │
Task 2 (SSH server setup — MANUAL) ──► Task 3 (ssh-copy-id) ──► Task 4 (scp SSH key)
                                                                          │
                                                                          ▼
                                          Task 5 (rsync GPG) ─────────────┤
                                          Task 6 (rsync terminalconfig) ──┤
                                          Task 7 (rsync terminal-apps) ───┘
                                                                          │
                                                                          ▼
                                          Task 8 (run install.sh — ATTENDED)
                                                                          │
                                                                          ▼
                                          Task 9 (git identity) ──► Task 10 (verify)
                                                                          │
                                                                          ▼
                                          Task 11 (commit plan)
```

Tasks 1, 5, 6, 7 are independent and can run in parallel on the workstation (all are rsync/scp to the same target). Tasks 2 → 3 → 4 are sequential (each depends on the previous). Task 8 must run after all transfers complete. Tasks 9 → 10 run after install.sh finishes.
