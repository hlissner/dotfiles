#!/usr/bin/env bash

# This script bootstraps arch linux with the utmost essentials. It expects an internet
# connection, and the harddrives to be set up (and one of the mounted to /mnt).

MOUNT=/mnt

exists() { command -v "$1" >/dev/null; }
arch() { arch-chroot "$MOUNT" /bin/bash -c "$1"; }
pac() { pacstrap "$MOUNT" $@; }

if ! exists arch-chroot; then
    >&2 echo "Meant to be run from the Arch Linux installer"
    exit 1
elif ! grep "$MOUNT " /proc/mounts >/dev/null; then
    >&2 echo "$MOUNT isn't mounted"
    exit 2
elif ! ping -c1 http://google.com >/dev/null; then
    >&2 echo "No internet connection detected!"
    exit 3
fi

#
set -e

## Collect info
# hostname
read -rp "Hostname:\t" host

#
echo "$host" > "$MOUNT/etc/hostname"

# ensure keys are up to date
pacman-key --refresh-keys
pacman -Syy

# bootstrap
pac base base-devel intel-ucode
# device mounting drivers
pac dosfstools ntfs-3g exfat-utils hfsprogs

# networking support
WIRELESS_DEV=$(ip link | grep wlp | awk '{print $2}'| sed 's/://' | sed '1!d')
if [[ -n $WIRELESS_DEV ]]; then
    echo "==> ${WIRELESS_DEV} interface detected"
    pac iw wireless_tools wpa_actiond wpa_supplicant dialog netctl
fi

WIRED_DEV=$(ip link | grep "en[sop]" | awk '{print $2}'| sed 's/://' | sed '1!d')
if [[ -n $WIRED_DEV ]]; then
    echo "==> ${WIRED_DEV} interface detected"
    arch "systemctl enable dhcpcd@${WIRED_DEV}.service"
fi
# Speed up connections on boot
if ! grep "^noarp$" $MOUNT/etc/dhcpcd.conf; then
    echo -e "\nnoarp" >> $MOUNT/etc/dhcpcd.conf
fi

# locale
sed -i '/^#en_US\.UTF-8/s/^#//' $MOUNT/etc/locale.gen
arch "locale-gen"
# datetime
pac ntp
arch "systemctl enable ntpd.service"
arch "ln -sfv /usr/share/zoneinfo/America/Toronto /etc/localtime"

# finalization
genfstab -U "$MOUNT" >> "$MOUNT/etc/fstab"
arch "bootctl --path=/boot install"
arch "mkinitcpio -p linux"
