#!/usr/bin/bash
# Configure TPM2 auto-unlock for a directly LUKS2-backed Fedora root filesystem.
# PCR 7 tracks Secure Boot policy and survives normal kernel updates. On Fedora's
# traditional GRUB layout, it does not authenticate the separate initramfs. A
# signed UKI with a PCR 11 policy is the stronger setup, but requires a different
# boot-image and signing workflow.
set -euo pipefail
export LC_ALL=C

if (( EUID != 0 )); then
    exec sudo -- "$0" "$@"
fi

for command in awk cryptsetup dracut findmnt lsinitrd mokutil systemd-cryptenroll; do
    command -v "$command" >/dev/null || {
        printf 'Required command is missing: %s\n' "$command" >&2
        exit 1
    }
done

root_source=$(findmnt -no SOURCE /)
root_mapper=${root_source%%\[*}
case "$root_mapper" in
    /dev/mapper/*) mapper=${root_mapper#/dev/mapper/} ;;
    *)
        printf 'Root is not directly backed by a /dev/mapper device: %s\n' "$root_source" >&2
        exit 1
        ;;
esac

crypt_status=$(cryptsetup status "$mapper")
crypt_type=$(awk '$1 == "type:" { print $2 }' <<< "$crypt_status")
device=$(awk '$1 == "device:" { print $2 }' <<< "$crypt_status")
if [[ $crypt_type != LUKS2 || -z $device ]]; then
    printf 'Root mapper %s is not a directly backed LUKS2 device.\n' "$mapper" >&2
    exit 1
fi

uuid=$(cryptsetup luksUUID "$device")
device="/dev/disk/by-uuid/$uuid"
crypttab=/etc/crypttab
dracut_config=/etc/dracut.conf.d/20-luks-tpm.conf
timestamp=$(date +%Y%m%d-%H%M%S)
backup_dir=/root/luks-header-backups
header_backup="$backup_dir/luks-$uuid-$timestamp.img"
crypttab_backup="/etc/crypttab.pre-tpm-$timestamp"
crypttab_tmp=
dracut_tmp=

cleanup() {
    if [[ -n $crypttab_tmp ]]; then rm -f -- "$crypttab_tmp"; fi
    if [[ -n $dracut_tmp ]]; then rm -f -- "$dracut_tmp"; fi
}
trap cleanup EXIT

printf 'Checking root LUKS2 volume %s and TPM...\n' "$device"
test -b "$device"
cryptsetup isLuks --type luks2 "$device"
secure_boot_state=$(mokutil --sb-state)
if [[ $secure_boot_state != 'SecureBoot enabled' ]]; then
    printf '%s\n' 'Secure Boot must be enabled before enrolling a PCR 7 TPM token.' >&2
    printf '%s\n' "$secure_boot_state" >&2
    exit 1
fi
systemd-cryptenroll --tpm2-device=list --no-pager |
    grep '^/dev/tpm' >/dev/null

mkdir -m 700 -p "$backup_dir"
cryptsetup luksHeaderBackup "$device" --header-backup-file "$header_backup"
chmod 600 "$header_backup"
printf 'LUKS header backup: %s\n' "$header_backup"

printf '%s\n' 'Enrolling one TPM 2.0 token with Secure Boot PCR 7.'
printf '%s\n' 'Enter the current disk passphrase when asked.'
systemd-cryptenroll "$device" \
    --tpm2-device=auto \
    --tpm2-pcrs=7 \
    --wipe-slot=tpm2

printf '%s\n' 'Testing TPM unlock with password fallback disabled...'
cryptsetup open \
    --type luks2 \
    --test-passphrase \
    --token-only \
    --token-type systemd-tpm2 \
    "$device"

if [[ ! -e $crypttab ]]; then
    install -m 600 -o root -g root /dev/null "$crypttab"
fi
install -m 600 -o root -g root "$crypttab" "$crypttab_backup"
crypttab_tmp=$(mktemp /etc/crypttab.tpm.XXXXXX)
awk -v name="$mapper" -v uuid="$uuid" '
function has_option(options, wanted, count, values, item) {
    count = split(options, values, ",")
    for (item = 1; item <= count; item++) {
        if (values[item] == wanted) return 1
    }
    return 0
}
function add_option(options, wanted) {
    if (has_option(options, wanted)) return options
    if (options == "" || options == "none") return wanted
    return options "," wanted
}
/^[[:space:]]*#/ || NF == 0 { print; next }
$1 == name || $2 == "UUID=" uuid || $2 == "/dev/disk/by-uuid/" uuid {
    key = (NF >= 3 ? $3 : "none")
    options = (NF >= 4 ? $4 : "none")
    options = add_option(options, "tpm2-device=auto")
    options = add_option(options, "x-initrd.attach")
    print name, "UUID=" uuid, key, options
    found = 1
    next
}
{ print }
END {
    if (!found) {
        print name, "UUID=" uuid, "none", "tpm2-device=auto,x-initrd.attach"
    }
}
' OFS='\t' "$crypttab" > "$crypttab_tmp"
install -m 600 -o root -g root "$crypttab_tmp" "$crypttab"
restorecon "$crypttab" 2>/dev/null || true

dracut_tmp=$(mktemp /etc/dracut.conf.d/20-luks-tpm.conf.XXXXXX)
printf '%s\n' \
    '# Include TPM userspace support in every early-boot image.' \
    'add_dracutmodules+=" tpm2-tss "' > "$dracut_tmp"
install -m 644 -o root -g root "$dracut_tmp" "$dracut_config"
restorecon "$dracut_config" 2>/dev/null || true

printf '%s\n' 'Rebuilding initramfs images for all installed kernels...'
dracut --regenerate-all --force

printf '%s\n' 'Verifying initramfs images for all installed kernels...'
verified_images=0
for modules_dir in /usr/lib/modules/*; do
    test -d "$modules_dir" || continue
    kernel_release=${modules_dir##*/}
    initramfs="/boot/initramfs-$kernel_release.img"
    test -f "$initramfs" || continue
    lsinitrd -f /etc/crypttab "$initramfs" |
        grep 'tpm2-device=auto' >/dev/null
    lsinitrd "$initramfs" |
        grep 'libcryptsetup-token-systemd-tpm2.so' >/dev/null
    lsinitrd -m "$initramfs" |
        grep 'tpm2-tss' >/dev/null
    printf 'Verified: %s\n' "$initramfs"
    ((verified_images += 1))
done
if (( verified_images == 0 )); then
    printf '%s\n' 'No installed-kernel initramfs images were found.' >&2
    exit 1
fi
cryptsetup luksDump "$device" |
    grep 'systemd-tpm2' >/dev/null

printf '\n%s\n' 'TPM enrollment, unlock test, crypttab update, and initramfs verification all passed.'
printf 'crypttab backup: %s\n' "$crypttab_backup"
printf 'LUKS header backup: %s\n' "$header_backup"
printf '%s\n' 'Keep the disk passphrase. It remains the recovery path if TPM unlock fails.'
