[![Made with Doom Emacs](https://img.shields.io/badge/Made_with-Doom_Emacs-blueviolet.svg?style=flat-square&logo=GNU%20Emacs&logoColor=white)](https://github.com/hlissner/doom-emacs)
[![NixOS Unstable](https://img.shields.io/badge/NixOS-unstable-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)

**Hey,** you. You're finally awake. You were trying to configure your OS
declaratively, right? Walked right into that NixOS ambush, same as us, and those
dotfiles over there.

> **Disclaimer:** _This is not a community framework or distribution._ It's a
> private configuration and an ongoing experiment while I feel out NixOS. I make
> no guarantees that it will work out of the box for anyone but myself. It may
> also change drastically and without warning. 
> 
> Until I can bend spoons with my nix-fu, please don't treat me like an
> authority or expert in the NixOS space. Seek help on [the NixOS
> discourse](https://discourse.nixos.org) instead.

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

1. Acquire NixOS 21.11 or newer:
   ```sh
   # Yoink nixos-unstable
   wget -O nixos.iso https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso
   
   # Write it to a flash drive
   cp nixos.iso /dev/sdX
   ```

2. Boot into the installer.

3. Switch to root user: `sudo su -`

4. Do your partitions and mount your root to `/mnt` ([for
   example](hosts/kuro/README.org)).

5. Install these dotfiles:
   ```sh
   nix-shell -p git nixFlakes

   # Set HOST to the desired hostname of this system
   HOST=...
   # Set USER to your desired username (defaults to hlissner)
   USER=...

   git clone https://github.com/hlissner/dotfiles /mnt/etc/nixos
   cd /mnt/etc/nixos
   
   # Create a host config in `hosts/` and add it to the repo:
   mkdir -p hosts/$HOST
   nixos-generate-config --root /mnt --dir /etc/nixos/hosts/$HOST
   rm -f hosts/$HOST/configuration.nix
   cp hosts/kuro/default.nix hosts/$HOST/default.nix
   vim hosts/$HOST/default.nix  # configure this for your system; don't use it verbatim!
   git add hosts/$HOST
   
   # Install nixOS
   USER=$USER nixos-install --root /mnt --impure --flake .#$HOST
   
   # If you get 'unrecognized option: --impure', replace '--impure' with 
   # `--option pure-eval no`.
   ```

6. Then reboot and you're good to go!

> :warning: **Don't forget to change your `root` and `$USER` passwords!** They
> are set to `nixos` by default.


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
    -d, --dryrun                     Don't change anything; perform dry run
    -D, --debug                      Show trace on nix errors
    -f, --flake URI                  Change target flake to URI
    -h, --help                       Display this help, or help for a specific command
    -i, -A, -q, -e, -p               Forward to nix-env
```

## Frequently asked questions

+ **Why NixOS?**

  Because declarative, generational, and immutable configuration is a godsend
  when you have a fleet of computers to manage.

+ **Should I use NixOS?**

  **Short answer:** no.
  
  **Long answer:** no really. Don't.
  
  **Long long answer:** no really, I'm not kidding. Don't.
  
  **Unsigned long long answer:** Ok ok. Do any of these sound like you?

  - You only have one (maybe two) systems to NixOS-ify.
  - You lack the discipline or dedication to learn a new language, google your
    issues, and trial'n'error your way to NixOS enlightenment -- all on your
    own.
  - "Declarative", "generational", and "immutable" don't make you _fully_ erect.
  - You're a unix virgin or have limited experience with Linux distros.
  - You arrived at NixOS by following trends, rather than your needs.
  - You need somebody else to tell you whether or not you need NixOS.
  
  **Then no, you should _not_ use NixOS.**

  - The learning curve is steep.
  - NixOS is unlike other Linux distros. Your issues will be unique and
    difficult to google.
  - The overhead of managing a NixOS config will rarely pay for itself with
    fewer than 3 systems.
  - Official documentation for Nix and NixOS is vast, but shallow.
  - Unofficial resources and example configs are sparse, tend to either be too
    simple or too complex, or outdated.
  - The Nix language is obtuse and its toolchain is complicated; multiply this
    by 1,000 if you've never touched the shell or a functional language before.
    And you _will_ have to learn Nix to do a fraction of what makes NixOS worth
    any of the trouble.
  - A decent grasp of Linux and its ecosystem is necessary to distinguish
    Nix/NixOS issues from conventional Linux issues (and to debug them).
    
  If none of this has deterred you, then you didn't need my advice in the first
  place. Stop procrastinating and try NixOS.

+ **How do you manage secrets?**

  With [agenix].

+ **Why did you write bin/hey?**

  I envy Guix's CLI and want similar for NixOS, whose toolchain is spread across
  many commands, none of which are as intuitive: `nix`, `nix-collect-garbage`,
  `nixos-rebuild`, `nix-env`, `nix-shell`.
  
  I don't claim `hey` is the answer, but everybody likes their own brew.
 
+ **How 2 flakes?**

  Would it be the NixOS experience if I gave you all the answers in one,
  convenient place?
  
  No. Suffer my pain:
  
  + [A three-part tweag article that everyone's read.](https://www.tweag.io/blog/2020-05-25-flakes/)
  + [An overengineered config to scare off beginners.](https://github.com/divnix/devos)
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
[agenix]: https://github.com/ryantm/agenix
