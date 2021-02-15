[![Made with Doom Emacs](https://img.shields.io/badge/Made_with-Doom_Emacs-blueviolet.svg?style=flat-square&logo=GNU%20Emacs&logoColor=white)](https://github.com/hlissner/doom-emacs)
[![NixOS 21.03](https://img.shields.io/badge/NixOS-v21.03-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)

**Hey,** you. You're finally awake. You were trying to configure your OS declaratively, right? Walked right into that NixOS ambush, same as us, and those dotfiles over there.

<img src="/../screenshots/alucard/fakebusy.png" width="100%" />

<p align="center">
<span><img src="/../screenshots/alucard/desktop.png" height="178" /></span>
<span><img src="/../screenshots/alucard/rofi.png" height="178" /></span>
<span><img src="/../screenshots/alucard/tiling.png" height="178" /></span>
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

1. Yoink the latest build of [NixOS 21.03][nixos].
2. Boot into the installer.
3. Do your partitions and mount your root to `/mnt` ([for example](hosts/kuro/README.org))
4. Install these dotfiles:
5. `nix-shell -p git nixFlakes`
6. `git clone https://github.com/hlissner/dotfiles /mnt/etc/nixos`
7. Install NixOS: `nixos-install --root /mnt --flake /mnt/etc/nixos#XYZ`, where
   `XYZ` is [the host you want to install](hosts/).  Use `#generic` for a
   simple, universal config, or create a sub-directory in `hosts/` for your device. See [host/kuro] for an example.
8. Reboot!
9. Change your `root` and `$USER` passwords!

## Management

And I say, `bin/hey`. [What's going on?](http://hemansings.com/)

| Command                    | Description                                                                |
|----------------------------|----------------------------------------------------------------------------|
| `hey check`                | Run tests and checks for this flake                                        |
| `hey gc`                   | Runs `nix-collect-garbage -d`. Use `--all` to clean up system profile too. |
| `hey rebuild`              | Rebuild this flake (shortcut: `hey re`)                                    |
| `hey rollback`             | Roll back to previous system generation                                    |
| `hey show`                 | Show flake outputs of this repo                                            |
| `hey ssh REMOTE [COMMAND]` | Run a `bin/hey` command on REMOTE over ssh                                 |
| `hey upgrade`              | Update flake lockfile and switch to it (shortcut: `hey up`)                |

## Frequently asked questions

+ **Why NixOS?**

  Because declarative, generational, and immutable configuration is a godsend
  when you have a fleet of computers to manage.
  
+ **How do I change the default username?**

  1. Set `USER` the first time you run `nixos-install`: `USER=myusername
     nixos-install --root /mnt --flake /path/to/dotfiles#XYZ`
  2. Or change `"hlissner"` in modules/options.nix.
  
+ **Why did you write bin/hey?**

  I'm nonplussed by the user story for nix's CLI tools and thought fixing it
  would be more productive than complaining about it on the internet. Then I
  thought, [why not do both](https://youtube.com/watch?v=vgk-lA12FBk)?
  
+ **How 2 flakes?**

  Would it be the NixOS experience if I gave you all the answers in one,
  convenient place?
  
  No, but here are some resources that helped me:
  
  + [A three-part tweag article that everyone's read.](https://www.tweag.io/blog/2020-05-25-flakes/)
  + [An overengineered config to scare off beginners.](https://github.com/nrdxp/nixflk)
  + [A minimalistic config for scared beginners.](https://github.com/colemickens/nixos-flake-example)
  + [A nixos wiki page that spells out the format of flake.nix.](https://nixos.wiki/wiki/Flakes)
  + [Official documentation that nobody reads.](https://nixos.org/learn.html)
  + [Some great videos on general nixOS tooling and hackery.](https://www.youtube.com/channel/UC-cY3DcYladGdFQWIKL90SQ)
  + A couple flake configs that I 
    [may](https://github.com/LEXUGE/nixos) 
    [have](https://github.com/bqv/nixrc)
    [shamelessly](https://git.sr.ht/~dunklecat/nixos-config/tree)
    [rummaged](https://github.com/utdemir/dotfiles)
    [through](https://github.com/purcell/dotfiles).
  + [Some notes about using Nix](https://github.com/justinwoo/nix-shorts)
  + [What helped me figure out generators (for npm, yarn, python and haskell)](https://myme.no/posts/2020-01-26-nixos-for-development.html)
  + [What y'all will need when Nix drives you to drink.](https://www.youtube.com/watch?v=Eni9PPPPBpg)


[doom-emacs]: https://github.com/hlissner/doom-emacs
[vim]: https://github.com/hlissner/.vim
[nixos]: https://releases.nixos.org/?prefix=nixos/unstable/
[host/kuro]: https://github.com/hlissner/dotfiles/tree/master/hosts/kuro
