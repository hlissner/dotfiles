<div align="center">
   
[![Made with Doom Emacs](https://img.shields.io/badge/Made_with-Doom_Emacs-blueviolet.svg?style=flat-square&logo=GNU%20Emacs&logoColor=white)](https://github.com/hlissner/doom-emacs)
[![NixOS 20.09](https://img.shields.io/badge/NixOS-v20.09-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)

</div>

**Hey,** you. You're finally awake. You were trying to configure your OS declaratively, right? Walked right into that NixOS ambush, same as us, and those dotfiles over there.

<img src="https://raw.githubusercontent.com/hlissner/dotfiles/screenshots/fluorescence/fakebusy.png" width="100%" />

<p align="center">
<span><img src="/../screenshots/fluorescence/desktop.png" height="178" /></span>
<span><img src="/../screenshots/fluorescence/rofi.png" height="178" /></span>
<span><img src="/../screenshots/fluorescence/tiling.png" height="178" /></span>
</p>

------

| | |
|-|-|
| **Shell:** | zsh + zgen |
| **DM:** | lightdm + lightdm-mini-greeter |
| **WM:** | bspwm + polybar |
| **Editor:** | [Doom Emacs][doom-emacs] (and occasionally [vim]) |
| **Terminal:** | st |
| **Launcher:** | rofi |
| **Browser:** | firefox |
| **GTK Theme:** | [Ant Dracula](https://github.com/EliverLara/Ant-Dracula) |

-----

## Quick start

1. Yoink [NixOS 20.09][nixos] (must be newer than Sept 12, 2020 for `nixos-install --flake`).
2. Boot into the installer.
3. Do your partitions and mount your root to `/mnt`
4. `git clone https://github.com/hlissner/dotfiles /etc/nixos`
5. Install NixOS: `nixos-install --root /mnt --flake #XYZ`, where `XYZ` is your
   hostname.  Use `#generic` for a simple, universal config.
6. OPTIONAL: Create a sub-directory in `hosts/` for your device. See [host/kuro]
   as an example.
7. Reboot!

## Management

And I say, `bin/hey`. [What's going on?](https://www.youtube.com/watch?v=ZZ5LpwO-An4)

| Command           | Description                                                     |
|-------------------|-----------------------------------------------------------------|
| `hey rebuild`     | Rebuild this flake (shortcut: `hey re`)                         |
| `hey upgrade`     | Update flake lockfile and switch to it (shortcut: `hey up`)     |
| `hey rollback`    | Roll back to previous system generation                         |
| `hey gc`          | Runs `nix-collect-garbage -d`. Use sudo to clean system profile |
| `hey push REMOTE` | Deploy these dotfiles to REMOTE (over ssh)                      |
| `hey check`       | Run tests and checks for this flake                             |
| `hey show`        | Show flake outputs of this repo                                 |

## Frequently asked questions

+ **How do I change the default username?**

  1. Set `USER` the first time you run `nixos-install`: `USER=myusername
     nixos-install --root /mnt --flake #XYZ`
  2. Or change `"hlissner"` in modules/options.nix.

+ **How do I "set up my partitions"?**

  My main host [has a README](hosts/kuro/README.org) you can use as a reference.
  I set up an EFI+GPT system and partitions with `parted` and `zfs`.
  
+ **How 2 flakes?**

  It wouldn't be the NixOS experience if I gave you all the answers in one,
  convenient place.


[doom-emacs]: https://github.com/hlissner/doom-emacs
[vim]: https://github.com/hlissner/.vim
[nixos]: https://releases.nixos.org/?prefix=nixos/20.09-small/
[host/kuro]: https://github.com/hlissner/dotfiles/tree/master/hosts/kuro
