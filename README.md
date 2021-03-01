[![Made with Doom Emacs](https://img.shields.io/badge/Made_with-Doom_Emacs-blueviolet.svg?style=flat-square&logo=GNU%20Emacs&logoColor=white)](https://github.com/hlissner/doom-emacs)
[![NixOS 21.05](https://img.shields.io/badge/NixOS-v21.05-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)

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

1. Yoink the latest build of [NixOS 21.05][nixos].
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

```
Usage: hey [global-options] [command] [sub-options]

Available Commands:
  check                  Run 'nix flake check' on your dotfiles
  gc                     Garbage collect & optimize nix store
  generations            Explore, manage, diff across generations
  help [SUBCOMMAND]      Show usage information for this script or a subcommand
  rebuild                Rebuild the current system's flake
  repl                   Open a nix-repl with nixpkgs and dotfiles preloaded
  rollback               Roll back to last generation
  search                 Search nixpkgs for a package
  show                   [ARGS...]
  ssh HOST [COMMAND]     Run a bin/hey command on a remote NixOS system
  swap PATH [PATH...]    Recursively swap nix-store symlinks with copies (or back).
  test                   Quickly rebuild, for quick iteration
  theme THEME_NAME       Quickly swap to another theme module
  update [INPUT...]      Update specific flakes or all of them
  upgrade                Update all flakes and rebuild system

Options:
    -d, --dryrun                     Don't change anything; preform dry run
    -D, --debug                      Show trace on nix errors
    -f, --flake URI                  Change target flake to URI
    -h, --help                       Display this help, or help for a specific command
    -i, -A, -q, -e, -p               Forward to nix-env
```

## Frequently asked questions

+ **Why NixOS?**

  Because declarative, generational, and immutable configuration is a godsend
  when you have a fleet of computers to manage.
  
+ **How do you manage secrets?**

  With [agenix].
  
+ **How do I change the default username?**

  1. Set the `USER` environment variable the first time you run `nixos-install`:
     `USER=myusername nixos-install --root /mnt --flake /path/to/dotfiles#XYZ`
  2. Or change `"hlissner"` in modules/options.nix.
  
+ **Why did you write bin/hey?**

  I envy Guix's CLI and want similar for NixOS, but its toolchain is spread
  across many commands, none of which are as intuitive: `nix`,
  `nix-collect-garbage`, `nixos-rebuild`, `nix-env`, `nix-shell`.
  
  I don't claim `hey` is the answer, but everybody likes their own brew.
 
+ **How 2 flakes?**

  Would it be the NixOS experience if I gave you all the answers in one,
  convenient place?
  
  No. Suffer my pain:
  
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
[agenix]: https://github.com/ryantm/agenix
