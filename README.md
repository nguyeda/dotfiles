# dotfiles

Single-machine dotfiles managed with [chezmoi](https://chezmoi.io). One source
tree, one bootstrap one-liner, one `role` axis that drives both _what installs_
and _what configs render_.

## Bootstrap a fresh machine

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply davnn
```

This will:

1. Install chezmoi if missing.
2. Clone this repo to `~/.local/share/chezmoi`.
3. Render `.chezmoi.toml.tmpl` — prompts only for **role**.
4. Run the install scripts in order:
   - `00-install-1password.sh` — the `op` CLI (skipped on devcontainer/ec2/pi).
   - `10-install-package-manager.sh` — Homebrew on mac; apt update on Debian.
   - `20-install-packages.sh` — role-branched package install.
   - `30-install-third-party.sh` — fnm, starship, uv, claude, opencode, jj.
5. Render every config file into `$HOME`.
6. Run the post-install scripts (interactive ones auto-skip when stdin is
   not a tty):
   - `40-generate-ssh-key.sh` — `ssh-keygen -t ed25519` if `~/.ssh/id_ed25519`
     is missing.
   - `50-configure-git.sh` — prompt for `user.name` / `user.email`, write them
     to `~/.gitconfig.local` (which is `[include]`'d by the chezmoi-managed
     `~/.gitconfig`, so future applies won't clobber it).
   - `60-configure-gh.sh` — `gh auth login` (optional), then check whether the
     local SSH public key is already on your GitHub account; if not, offer to
     `gh ssh-key add` it (default title = hostname).
   - `install-fonts.sh`, `install-{vscode,cursor}-extensions.sh`,
     `install-tpm.sh`.

### Non-interactive (CI / devcontainer / EC2 user-data)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply davnn \
    --promptChoice role=devcontainer
```

The git/gh/ssh post-install scripts skip themselves when stdin is not a tty,
so this is safe in non-interactive bootstrap. Set git user manually after:

```bash
git config -f ~/.gitconfig.local user.name 'Your Name'
git config -f ~/.gitconfig.local user.email 'you@example.com'
```

## Roles

| Role             | When to pick it                              | Skips                                |
| ---------------- | -------------------------------------------- | ------------------------------------ |
| `desktop-mac`    | Your Mac.                                    | nothing                              |
| `desktop-fedora` | Fedora workstation (with or without NVIDIA). | nothing                              |
| `devcontainer`   | VSCode devcontainers, Codespaces.            | tmux, ghostty, claude, vscode, fonts |
| `pi`             | Raspberry Pi running Debian/Raspbian.        | ghostty, aerospace, fonts            |
| `ec2`            | EC2 / cloud Linux box (Debian or Amazon).    | ghostty, aerospace, claude, fonts    |

NVIDIA driver setup (Fedora desktop only) auto-detects via `lspci` and only
runs when a GPU is present.

## Common commands

```bash
chezmoi diff           # show pending changes
chezmoi apply -v       # render + execute
chezmoi update -v      # git pull + apply
chezmoi edit ~/.zshrc  # edit the source, not the rendered file
chezmoi edit-config    # change role after init
chezmoi cd             # cd into the source tree
```

## Secrets (1Password)

Templates resolving secrets use `onepasswordRead` / `onepassword` and require
`op signin` to have been run **once** on the machine. Subsequent applies reuse
the cached session. Roles that don't sign into 1Password (devcontainer, ec2,
pi) skip the install entirely; templates that reference 1P functions are gated
by role and never render on those machines.

## Layout

```
# ── chezmoi metadata ────────────────────────────────────────────────────────
.chezmoi.toml.tmpl                       # init prompts (role only)
.chezmoiignore.tmpl                      # role/OS file gating
.chezmoiexternal.toml.tmpl               # external git clones (TPM)

# ── install scripts (run once / on YAML change) ─────────────────────────────
run_once_before_00-install-1password.sh.tmpl
run_once_before_10-install-package-manager.sh.tmpl
run_onchange_before_20-install-packages.sh.tmpl   # delegates to install/install.sh
run_once_before_30-install-third-party.sh.tmpl
run_once_after_40-generate-ssh-key.sh.tmpl
run_once_after_50-configure-git.sh.tmpl
run_once_after_60-configure-gh.sh.tmpl
run_once_after_install-fonts.sh.tmpl
run_once_after_install-vscode-extensions.sh.tmpl
run_once_after_install-cursor-extensions.sh.tmpl
run_once_after_install-tpm.sh.tmpl

# ── package manifests (the "what to install" recipes) ───────────────────────
packages/recipes.yaml                    # role → distro groups + common tools
packages/macos.yaml                      # brew formulas / casks / taps groups
packages/fedora.yaml                     # dnf groups
packages/debian.yaml                     # apt groups (covers pi/ec2/devcontainer)
packages/common.yaml                     # cross-distro curl installers

# ── installer machinery ─────────────────────────────────────────────────────
install/install.sh                       # entry point — read recipes.yaml, dispatch
install/lib/{common,yaml,fedora,debian,macos,common-tools}.sh

# ── support files ───────────────────────────────────────────────────────────
extensions/{vscode,cursor}.txt
fonts/fonts.txt

# ── rendered home dotfiles ──────────────────────────────────────────────────
dot_zshrc.tmpl                           → ~/.zshrc
dot_gitconfig.tmpl                       → ~/.gitconfig
dot_gitignore_global                     → ~/.gitignore_global
dot_tmux.conf                            → ~/.tmux.conf
dot_yabairc                              → ~/.yabairc        (mac)
dot_skhdrc                               → ~/.skhdrc         (mac)
dot_zsh/                                 → ~/.zsh/
dot_config/...                           → ~/.config/...
private_dot_claude/                      → ~/.claude/        (0700)
```

## Editing the package list

To add a Fedora package, edit `packages/fedora.yaml`:

```yaml
groups:
  cli:
    packages:
      - btop
      - gh
      - just
      - htop          # ← add here
```

To shift a role's group selection, edit `packages/recipes.yaml`:

```yaml
roles:
  desktop-fedora:
    fedora: [core, cli, git-ui, terminals, iac, editors, gui-extras, cloud, docker, nvidia]
                                                                                # ↑ add/remove groups
```

Run `./install/install.sh --list-roles` and `./install/install.sh --list-groups fedora`
to inspect what's available.

You can re-run the installer outside chezmoi for fast iteration:

```bash
./install/install.sh --role desktop-fedora --groups cli,git-ui
```

See [`CLAUDE.md`](./CLAUDE.md) for AI-agent-oriented conventions and a
"how to add a new package / config" walk-through.
