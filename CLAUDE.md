# Dotfiles Project Guide (chezmoi)

This repository contains a [chezmoi](https://chezmoi.io) source tree under
`home/`. The repo root contains installer/package machinery. `.chezmoiroot`
points chezmoi at `home/`.

## Mental Model

- `chezmoi apply` is config-only.
- Package installation is explicit: `just install`, `just plan`, or
  `./install.sh`.
- `recipe/<environment>.yaml` maps each environment to exact package manifest IDs.
- Each package/tool group has one manifest: `apps/<id>.yaml`.
- The installer chooses `install.<distro>`, then `install.<os>`, then
  `install.default`.

## Package Manifests

Use one YAML file per package/tool group:

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

Supported install keys:

| Key | Meaning |
|---|---|
| `packages` | Exact package names for brew/dnf/apt. |
| `casks` | Exact Homebrew casks. |
| `flatpaks` | Exact Flathub app IDs. |
| `taps` | Homebrew taps required before formulas/casks. |
| `pre_install` | Repo/key setup before package-manager install. |
| `script` | Full custom upstream install script. Do not combine with `packages`. |
| `post_install` | Commands to run after install. |
| `detect` | Shell expression; skip if it fails. |
| `check` | Shell expression for installed state. Overrides package checks. |
| `optional` | Allow package-manager install failure. |

Prefer descriptive package metadata (`packages`, `casks`, `flatpaks`) whenever
possible so `just plan` can show exactly what would be installed. Use
`pre_install` for repository/key setup before package-manager installs. Use
`script` only for upstream installers that do not use the package manager.

## Commands

```bash
just plan
just plan --force
just install
just install --force
just install desktop-fedora
just install macos
./install.sh --package jj --dry-run
./install.sh --list-packages
./install.sh --init --role macos
```

## Adding A Package

1. Add `apps/<id>.yaml`.
2. Add `<id>` to the relevant `recipe/<environment>.yaml` package list.
3. Run `just plan <role>` or `./install.sh --role <role> --dry-run`.

## Adding Config

1. Put chezmoi source files under `home/` using chezmoi filename grammar.
2. Use `home/.chezmoiignore.tmpl` for role/OS excludes.
3. Verify with `just diff` or `chezmoi diff --source .`.

## Don't

- Do not add package installation back to chezmoi `run_*` scripts.
- Do not edit rendered files in `$HOME`; edit the source under `home/`.
- Do not commit secrets; use 1Password references.
