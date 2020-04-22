[![Made with Doom Emacs](https://img.shields.io/badge/Made_with-Doom_Emacs-blueviolet.svg?style=flat-square&logo=GNU%20Emacs&logoColor=white)](https://github.com/hlissner/doom-emacs)
[![NixOS 20.03](https://img.shields.io/badge/NixOS-v20.03-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)

![Me looking busy](/../screenshots/fluorescence/fakebusy.png?raw=true)

<p align="center">
<span><img src="/../screenshots/fluorescence/desktop.png?raw=true" height="188" /></span>
<span><img src="/../screenshots/fluorescence/rofi.png?raw=true" height="188" /></span>
<span><img src="/../screenshots/fluorescence/tiling.png?raw=true" height="188" /></span>
</p>

# My dotfiles

+ **Operating System:** NixOS
+ **Shell:** zsh + zgen
+ **DM:** lightdm + lightdm-mini-greeter
+ **WM:** bspwm + polybar
+ **Editor:** [Doom Emacs][doom-emacs] (and occasionally [vim][vimrc])
+ **Terminal:** st
+ **Launcher:** rofi
+ **Browser:** firefox
+ **GTK Theme:** [Ant Dracula](https://github.com/EliverLara/Ant-Dracula)
+ **Icon Theme:** [Paper Mono Dark](https://github.com/snwh/paper-icon-theme)

*Works on my machine* ¯\\\_(ツ)_/¯

## Quick start

```sh
# Assumes your partitions are set up and root is mounted on /mnt
git clone https://github.com/hlissner/dotfiles /etc/dotfiles
make -C /etc/dotfiles install
```

Which is equivalent to:

```sh
USER=${USER:-hlissner}
HOST=${HOST:-kuro}
NIXOS_VERSION=20.03
DOTFILES=/home/$USER/.dotfiles

git clone https://github.com/hlissner/dotfiles /etc/dotfiles
ln -s /etc/dotfiles $DOTFILES
chown -R $USER:users $DOTFILES

# make channels
nix-channel --add "https://nixos.org/channels/nixos-${NIXOS_VERSION}" nixos
nix-channel --add "https://github.com/rycee/home-manager/archive/release-${NIXOS_VERSION}.tar.gz" home-manager
nix-channel --add "https://nixos.org/channels/nixpkgs-unstable" nixpkgs-unstable

# make /etc/nixos/configuration.nix
nixos-generate-config --root /mnt
echo "import /etc/dotfiles \"$$HOST\" \"$$USER\"" >/mnt/etc/nixos/configuration.nix

# make install
nixos-install --root /mnt -I "my=/etc/dotfiles"
```

### Management

+ `make` = `nixos-rebuild test`
+ `make switch` = `nixos-rebuild switch`
+ `make upgrade` = `nix-channel --update && nixos-rebuild switch`
+ `make install` = `nixos-generate-config --root $PREFIX && nixos-install --root
  $PREFIX`
+ `make gc` = `nix-collect-garbage -d` (use sudo to clear system profile)


[doom-emacs]: https://github.com/hlissner/doom-emacs
[vimrc]: https://github.com/hlissner/.vim
