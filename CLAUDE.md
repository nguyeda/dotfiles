# Dotfiles Project Guide (chezmoi)

This repository is a [chezmoi](https://chezmoi.io) source tree. It replaced a
previous GNU Stow setup. The defining axis is `role` (prompted at `chezmoi
init`, persisted to `~/.config/chezmoi/chezmoi.toml`); every install script
and template branches on it.

## Mental model

- **One source tree, every machine.** chezmoi clones this repo to
  `~/.local/share/chezmoi` and renders files into `$HOME`. There is no
  per-machine `.local` overlay file pattern anymore — divergence happens via
  Go templates (`.tmpl`).
- **Files vs. scripts.** Filenames that start with `dot_`, `private_`,
  `executable_`, `encrypted_` map to real files in `$HOME` (with the prefix
  decoded). Filenames that start with `run_once_*`, `run_onchange_*`,
  `run_*` execute on apply.
- **Role drives everything.** Five roles: `desktop-mac`, `desktop-fedora`,
  `devcontainer`, `pi`, `ec2`. Read with `{{ .role }}` in any template.

## Filename grammar (read this before writing files)

| Source filename                      | Lands at                          |
| ------------------------------------ | --------------------------------- |
| `dot_zshrc`                          | `~/.zshrc`                        |
| `dot_zshrc.tmpl`                     | `~/.zshrc` (after templating)     |
| `dot_tmux.conf`                      | `~/.tmux.conf`                    |
| `dot_config/foo/bar.conf`            | `~/.config/foo/bar.conf`          |
| `private_dot_claude/settings.json`   | `~/.claude/settings.json` (0600)  |
| `dot_zsh/executable_run.sh`          | `~/.zsh/run.sh` (chmod +x)        |
| `run_once_before_X.sh.tmpl`          | executes once before files render |
| `run_once_after_X.sh.tmpl`           | executes once after files render  |
| `run_onchange_before_X.sh.tmpl`      | re-runs when rendered text differs|

`run_once_*` invalidates by hash of the **rendered** script — change the
template body, it re-runs once. `run_onchange_*` is the same, but the typical
use is for declarative install lists where you _want_ a re-run on every change.

## Branching in templates

```gotmpl
{{- if eq .chezmoi.os "darwin" }}
brew install foo
{{- else if eq .chezmoi.osRelease.id "fedora" }}
sudo dnf install -y foo
{{- end }}

{{- if eq .role "devcontainer" }}
... only inside a devcontainer ...
{{- end }}

{{ .role }}      {{/* prompted at init */}}
```

Common variables:
- `.chezmoi.os` — `darwin`, `linux`
- `.chezmoi.osRelease.id` — `fedora`, `debian`, `ubuntu`, `raspbian`, `amzn`
- `.chezmoi.hostname`
- `.chezmoi.username`
- `.role` — the only custom value (from `.chezmoi.toml.tmpl`).
  Git user name/email come from the post-install `50-configure-git.sh`
  script, which writes them to `~/.gitconfig.local`.

## Adding a new install step

Package install uses **YAML manifests + a per-distro installer**:

```
packages/
├── recipes.yaml     # role → list of groups (the "target")
├── fedora.yaml      # dnf groups: packages, coprs, repos, custom, post_install
├── debian.yaml      # apt groups
└── common.yaml      # cross-distro curl installers (fnm, claude, etc.)

install/
├── install.sh       # entry point: ./install.sh --role <role>
└── lib/
    ├── common.sh         # logging + distro detection + ensure_yq
    ├── yaml.sh           # yq wrappers
    ├── fedora.sh / debian.sh / macos.sh / common-tools.sh
```

Pick the right file based on what kind of install it is:

| New thing | Where to add it |
|---|---|
| Fedora dnf package | `packages/fedora.yaml` → an existing or new `groups.<name>.packages: [...]` |
| Fedora COPR-only package | `packages/fedora.yaml` → `groups.<name>.coprs: [{copr, packages}]` |
| Fedora package needing custom .repo | `packages/fedora.yaml` → `groups.<name>.repos: [{file, contents \| from_repofile \| from_url, packages}]` |
| Fedora curl-installer / one-off | `packages/fedora.yaml` → `groups.<name>.custom: [{name, check, script}]` |
| Debian/Pi apt package | `packages/debian.yaml` → `groups.<name>.packages: [...]` |
| Debian custom apt repo | `packages/debian.yaml` → `groups.<name>.apt_keys + apt_sources + packages` |
| Cross-distro curl installer | `packages/common.yaml` → new entry under `groups.` |
| New role / changed group selection | `packages/recipes.yaml` → edit `roles.<role>` |
| macOS package | `packages/macos.yaml` → `groups.<name>.formulas` / `casks` / `taps` |
| New helper function in installer | `install/lib/<distro>.sh` |

After editing any YAML, the SHA-256 of every manifest is embedded in
`run_onchange_before_20-install-packages.sh.tmpl`, so the next `chezmoi apply`
sees a changed rendered script and re-runs the installer automatically.

`./install/install.sh --role <role>` can also be run **standalone**, outside
chezmoi — useful for testing changes without going through `chezmoi apply`.
Use `--list-roles`, `--list-groups <distro>`, or
`--groups core,cli` to scope down what runs.

## Adding a new config file

1. Drop the file into the source tree using the chezmoi filename grammar
   above. Mirror `$HOME` paths via `dot_config/`, `dot_<file>`, or
   `private_dot_<dir>/`.
2. If it should _only_ exist on some roles/OSes, add a line to
   `.chezmoiignore.tmpl` that gates it.
3. If it needs templating, append `.tmpl` and use Go template syntax.
4. Verify with `chezmoi diff` (no apply) and then `chezmoi apply -v`.

## Adding role-specific divergence

Three options, in order of preference:

1. **Template the file.** `.tmpl` extension + `{{ if eq .role ... }}` blocks.
   Best for files where most contents are identical and only a few lines vary
   (e.g. `dot_gitconfig.tmpl` differs only in the credential-helper block).
2. **Ignore the file on roles that don't need it.** Add a path to
   `.chezmoiignore.tmpl` under the appropriate `if`. Best for whole-file
   excludes (e.g. yabairc has no meaning outside macOS).
3. **Branch in install scripts.** Already used heavily in the
   `run_*-install-*.sh.tmpl` files; the file system stays identical, only
   the install side differs.

## Code intelligence

Prefer LSP over Grep/Read for code navigation — it's faster, precise, and
avoids reading entire files:

- `workspaceSymbol` to find where something is defined
- `findReferences` to see all usages across the codebase
- `goToDefinition` / `goToImplementation` to jump to source
- `hover` for type info without reading the file

Use Grep only when LSP isn't available or for text/pattern searches (comments,
strings, config).

After writing or editing code, check LSP diagnostics and fix errors before
proceeding.

## Testing changes safely

```bash
# Preview without writing
chezmoi diff

# Verbose dry-run apply (renders + would-execute scripts)
chezmoi apply --dry-run -v

# Apply for real
chezmoi apply -v

# After applying, verify it's a no-op the second time (idempotency)
chezmoi apply -v   # expect 0 changes
```

Re-running a `run_once_*` script: delete its hash entry from
`~/.config/chezmoi/chezmoistate.boltdb` (or use `chezmoi state delete-bucket
--bucket=scriptState`).

## Secrets (1Password)

Templates can reference:

```gotmpl
{{ (onepasswordRead "op://Personal/GitHub/token") }}
{{ (onepassword "GitHub Signing Key").fields[0].value }}
```

Both require `op signin` to have happened on the machine. The
`run_once_before_00-install-1password.sh.tmpl` script installs `op` but does
not sign in — that's a one-time manual step per machine. Roles that aren't
expected to authenticate (devcontainer, ec2, pi) skip the install and any
template that uses 1P functions must be gated by role.

## Don't

- Don't edit `~/.zshrc` (or other rendered files) directly. Use
  `chezmoi edit ~/.zshrc` (which opens the source `.tmpl` in `$EDITOR`).
- Don't add `.local` overlay files (the old stow pattern). Template instead.
- Don't commit secrets; use 1Password references.
