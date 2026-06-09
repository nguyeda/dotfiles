# dotfiles

Single-machine dotfiles managed with [chezmoi](https://chezmoi.io). The repo
root holds installer/package machinery, `home/` is the chezmoi source tree, and
`role` drives both install selection and config rendering.

## Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply nguyeda
```

The repo root contains `.chezmoiroot`, so chezmoi reads source state from
`home/`. For a full machine setup from an existing checkout:

```bash
./install.sh --init --role desktop-mac
```

`chezmoi apply` is config-only. Package installation is explicit.

## Commands

```bash
just setup desktop-fedora      # bootstrap, install packages, then apply config
just plan                     # preview install work for current role
just install                  # install packages for current role
just install --force          # run installers even if checks pass
just install macos            # alias for desktop-mac
just install fedora           # alias for desktop-fedora
just install desktop-fedora   # install packages for an explicit role
just install-tool opencode     # install one package manifest
just apply                    # config-only chezmoi apply
just diff                     # show pending config changes
```

## Package Model

`recipe/<environment>.yaml` maps each environment to exact package manifest IDs:

```yaml
packages:
  - git
  - jj
  - opencode
```

Each package or tool group has its own manifest at `apps/<id>.yaml`:

```yaml
id: jj
description: Jujutsu VCS
check: command -v jj
install:
  macos:
    packages: [jj]
  default:
    script: |
      # upstream binary install script
```

Installer selection order is: `install.<distro>` -> `install.<os>` ->
`install.default`. For example, macOS uses `install.macos`; Fedora uses
`install.fedora`; Debian/Ubuntu/Raspbian use `install.debian`; other Linux
systems can use `install.linux` or `default`.

Install blocks run in this order: `pre_install`, package-manager entries,
`script`, then `post_install`. Use `pre_install` for repo/key setup. Use
`script` only for custom upstream installers, and do not combine it with
`packages`.

Dry-run output is package-level and concrete:

```text
[install] plan: package=jj manifest=jj install=macos manager=brew status=installed action=none
[install] plan: package=slack manifest=slack install=macos manager=brew-cask status=missing action=would-install
```

## Layout

```text
.chezmoiroot                  # points chezmoi at home/
home/                         # chezmoi source tree
install.sh                    # package installer and bootstrap entrypoint
install/lib/packages.sh       # package manifest runner
recipe/<environment>.yaml     # environment -> package IDs
apps/<id>.yaml                # one manifest per package/tool group
extensions/                   # editor extension lists used by package manifests
fonts/                        # font list used by fonts manifest
```

## Roles

| Role             | When to pick it                              |
| ---------------- | -------------------------------------------- |
| `desktop-mac`    | Your Mac.                                    |
| `desktop-fedora` | Fedora workstation.                          |
| `devcontainer`   | VSCode devcontainers, Codespaces.            |
| `pi`             | Raspberry Pi running Debian/Raspbian.        |

Convenience aliases: `macos` resolves to `desktop-mac`; `fedora` resolves to
`desktop-fedora`.

## Secrets

Templates resolving secrets use `onepasswordRead` / `onepassword` and require
`op signin` once on the machine. Desktop roles include `1password-cli`; roles
without 1Password access do not.
