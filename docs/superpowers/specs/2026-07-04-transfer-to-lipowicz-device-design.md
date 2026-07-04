# Transfer terminal environment to lipowicz@100.102.244.16

Design for transferring the full terminal environment (terminalconfig bootstrap +
terminal-applications reference docs + key dotfiles) from this workstation to the
Ubuntu device at 100.102.244.16.

## Approach

Combined rsync transfer (Approach C). Single batch of rsync/scp commands copies
the terminalconfig repo, terminal-applications docs, SSH key, and GPG keys to
the target, then install.sh runs the bootstrap in place.

## Target state

| Machine | IP | OS | User |
|---------|----|----|------|
| Target | 100.102.244.16 | Ubuntu 24.04+ (apt-based) | lipowicz |

Ping: sub-millisecond. SSH server not running yet.
Assumes Ubuntu 24.04+ (required by terminalconfig install.sh for package availability).

## Phases

### Phase 0: Pre-flight (workstation)

Commit any staged changes in ~/terminalconfig and push to GitHub so the repo
state is clean before transfer:

```bash
cd ~/terminalconfig
git add -A && git commit -m "cleanup: pre-transfer sync"
git push
```

### Phase 1: SSH server setup (manual, on target)

Requires physical/console access to the target machine.

```bash
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
```

Test from workstation:

```bash
ssh -o ConnectTimeout=5 lipowicz@100.102.244.16 echo ok
```

Copy SSH public key for passwordless auth:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub lipowicz@100.102.244.16
```

### Phase 2: File transfer (workstation → target)

All transfers happen before running install.sh. Order matters: the SSH private
key must be on the target before 05-auth.sh runs (it checks for existing keys
and skips generation).

```bash
# SSH identity (so 05-auth.sh skips key generation)
scp ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub \
  lipowicz@100.102.244.16:~/.ssh/

# GPG keys (needed for pass password-store)
rsync -avz ~/.gnupg/ lipowicz@100.102.244.16:~/.gnupg/

# terminalconfig repo (including .git for future pulls)
rsync -avz ~/terminalconfig/ lipowicz@100.102.244.16:~/terminalconfig/

# terminal-applications reference docs (referenced by OpenCode config)
rsync -avz ~/terminal-applications/ lipowicz@100.102.244.16:~/terminal-applications/
```

### Phase 3: Run bootstrap (on target, via SSH)

```bash
ssh lipowicz@100.102.244.16
cd ~/terminalconfig
./install.sh
```

The bootstrap runs five phases:

| Phase | Script | What it does |
|-------|--------|-------------|
| 1/4 | 01-packages.sh | apt, Rust, Cargo tools, pipx, uv, npm globals |
| 2/4 | 02-fonts.sh | JetBrains Mono Nerd Font |
| 3/4 | 03-oh-my-zsh.sh | Oh My Zsh, Powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting |
| 4/4 | 04-deploy.sh | Backs up existing configs, symlinks repo configs to ~/.config/ and ~/ |
| 5/5 | 05-auth.sh | SSH key (skipped if exists), keychain, Bitwarden CLI |

install.sh will prompt for sudo password during apt installs and npm global
installs.

### Phase 4: Post-install (on target)

Manual steps after bootstrap completes:

```bash
# Git identity (the repo .gitconfig only has delta/pager config)
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Restart shell
exec zsh
```

Optional credential setup (accounts and keys still need interactive login):

```bash
gh auth login        # GitHub CLI
doppler login        # Doppler secrets
pass init <gpg-id>   # password-store
```

## What gets transferred

| Item | Source | Target path | Size |
|------|--------|-------------|------|
| SSH identity | ~/.ssh/id_ed25519{,.pub} | ~/.ssh/ | ~1KB |
| GPG keys | ~/.gnupg/ | ~/.gnupg/ | 36KB |
| terminalconfig | ~/terminalconfig/ | ~/terminalconfig/ | 6.1MB |
| terminal-applications | ~/terminal-applications/ | ~/terminal-applications/ | 232KB |

Total: ~6.4MB.

## What is NOT transferred

- Git user.name/user.email (not set globally on workstation; must be set manually on target)
- Doppler session token (needs `doppler login`)
- GitHub CLI auth (needs `gh auth login`)
- Obsidian vault contents (config only, via terminalconfig)
- Browser profiles, application settings outside the terminal

## Verification

After install:

```bash
zsh -c 'echo $SHELL'           # should print /usr/bin/zsh
nvim --version                 # Neovim installed
tmux -V                        # tmux installed
eza --version                  # eza installed
rg --version                   # ripgrep installed
bat --version                  # bat installed
ls -la ~/.zshrc                # should be symlink to ~/terminalconfig/home/.zshrc
ls -la ~/.config/nvim          # should be symlink to ~/terminalconfig/config/nvim
```

## Risks

- **Ubuntu version**: install.sh assumes Ubuntu 24.04+. Packages like ghostty and
  yazi may not exist in older apt repos. Verify target OS version before starting.
- **sudo prompts during install.sh**: Install pauses for password input over SSH.
  Mitigation: user must be present to type sudo password during Phase 3.
- **apt repo staleness**: Target may need `sudo apt update` before install.sh if
  package lists are stale (01-packages.sh already runs `sudo apt update`).
- **GPU-specific env vars**: .zshrc.tmpl has {{HIP_VISIBLE_DEVICES}},
  {{HSA_OVERRIDE_GFX_VERSION}}, and {{HIP_FORCE_DEV_KERNARG}} template vars
  for AMD GPU compute. These default to reasonable values but may need
  adjustment on a different GPU.
- **GPG trust**: Exported GPG keys will show untrusted status on the target.
  `pass init` will need the key ID to re-establish trust.
