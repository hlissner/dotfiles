#!/usr/bin/env zsh

sudo pacman --noconfirm --needed -S udevil devmon
sudo systemctl enable devmon@$USER
sudo systemctl start devmon@$USER

ARCH=$(cd "${0:A:h}/.." && pwd)
sudo sed -i "s@^# \(success_exec =\)@\1 $ARCH/bin/notify-mount@" /etc/udevil/udevil.conf
