#!/usr/bin/env bash

if ! grep -e '^[multilib]' /etc/pacman.conf >/dev/null; then
  echo "[multilib]\nInclude = /etc/pacman.d/mirrorlist" | \
    sudo tee -a /etc/pacman.conf
  sudo pacman -Sy
fi

sudo pacman --needed -S steam

