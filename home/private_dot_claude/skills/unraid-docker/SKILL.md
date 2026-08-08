---
name: unraid-docker
description: Add, recreate, or inspect Docker containers on the Unraid server (host `tower`) over SSH, so they stay visible and editable in the Unraid webGui. Use whenever a container needs creating or changing on tower/Unraid. Do NOT use plain `docker run` there - it produces orphan containers the UI cannot edit.
---

# Managing Docker on Unraid from the CLI

The Unraid box is `tower` (SSH alias, root). No docker compose, no Compose Manager
plugin, and they are not wanted.

## Why not plain `docker run`

Unraid's Docker tab treats a container as *manageable* only when both exist:

1. A template XML in `/boot/config/plugins/dockerMan/templates-user/`, matched to the
   container by its `<Name>` **element** - the filename is irrelevant.
2. The label `net.unraid.docker.managed=dockerman` on the container.

A bare `docker run` gives neither, so the container shows up as an orphan with Edit
greyed out. Use `dockerman` instead: it feeds the template through Unraid's own
`xmlToCommand()`, producing a container byte-identical to a UI-created one.

## Bootstrap (run first, every session that touches tower)

`dockerman` is bespoke - written for this setup, not upstream. The copy next to this
file is canonical. `/usr/local/bin` on Unraid is tmpfs, so the flash copy plus the `go`
file is what survives reboots.

```bash
SKILL_DIR=~/.claude/skills/unraid-docker
if ! ssh tower 'cmp -s /boot/config/plugins/dockerMan/dockerman -' < "$SKILL_DIR/dockerman"; then
  ssh tower 'cat > /boot/config/plugins/dockerMan/dockerman \
    && install -m 0755 /boot/config/plugins/dockerMan/dockerman /usr/local/bin/dockerman \
    && php -l /usr/local/bin/dockerman' < "$SKILL_DIR/dockerman"
fi
# reboot persistence (idempotent)
ssh tower 'grep -q dockerman /boot/config/go || printf "\n# make dockerman CLI available after reboot\ninstall -m 0755 /boot/config/plugins/dockerMan/dockerman /usr/local/bin/dockerman\n" >> /boot/config/go'
```

If you change `dockerman`, edit the copy in this skill directory and re-run the
bootstrap - never edit the server copy directly, or the repo loses the change.

## Usage

Run `ssh tower dockerman` with no arguments for the authoritative flag list. Two verbs:

```bash
# scaffold a template, review it, then create the container
ssh tower "dockerman new <name> <image> -p 8080:80 -v /mnt/user/appdata/foo:/config -e TZ=Europe/Brussels"
ssh tower "dockerman <name>"

# or do both at once
ssh tower "dockerman new <name> <image> -p 8080:80 --apply"

# recreate / pull-and-update an existing container
ssh tower "dockerman <name>"
ssh tower "dockerman <name> --dry-run"   # print the docker command, change nothing
```

`dockerman <name>` pulls the image, creates missing bind-mount host paths, removes the
old container, recreates it, and seeds the update-status cache. It is idempotent -
re-running it is the normal way to apply a template edit.

Always `--dry-run` first when touching a container that matters.

## Gotchas

- **Templates match on `<Name>`, not filename.** Two templates with the same `<Name>`
  is undefined behaviour.
- **Editing in the webGui rewrites the same XML**, so CLI and UI compose freely in both
  directions. The template on flash is the source of truth.
- **Autostart is not in the template.** It is a newline-separated list at
  `/var/lib/docker/unraid-autostart` that also encodes start *order*; edit deliberately
  or use the UI toggle.
- **`<Icon>` must be a reachable PNG/SVG URL** or the UI shows a `?` placeholder.
  `dockerman new` warns on a non-200.
- **No YAML parser on the box** - no `yaml_parse`, no `yq`, no Python. Only Perl. Any
  YAML work has to happen locally and be pushed.
- **`dockerman` calls Unraid internals** (`xmlToCommand`, `DockerTemplates`,
  `DockerUpdate`) from `/usr/local/emhttp/plugins/dynamix.docker.manager/`. An Unraid
  upgrade could change those signatures. Failure is loud - a PHP fatal, not a silently
  wrong container - but re-run `--dry-run` after any OS update. Verified on 7.3.1.
- PHP fatals print nothing by default. To debug:
  `ssh tower 'php -d display_errors=1 /usr/local/bin/dockerman <args>'`

## Inspecting what the UI sees

```bash
ssh tower 'php -r "
\$docroot=\"/usr/local/emhttp\";
require_once \"\$docroot/webGui/include/Wrappers.php\";
require_once \"\$docroot/plugins/dynamix.docker.manager/include/DockerClient.php\";
\$i=(new DockerTemplates())->getAllInfo(true)[\"<name>\"];
foreach([\"template\",\"url\",\"icon\",\"running\",\"autostart\"] as \$k) echo \"\$k = \".json_encode(\$i[\$k]??null).\"\n\";
"'
```

A populated `template` key is the proof a container is manageable rather than orphaned.
