[![Tests](https://img.shields.io/github/actions/workflow/status/hlissner/dotfiles/test.yml?branch=master&style=flat-square&label=hey%20test&logo=GitHub&logoColor=white)](https://github.com/hlissner/dotfiles/actions/workflows/test.yml)
[![Made with Doom Emacs](https://img.shields.io/badge/Made_with-Doom_Emacs-blueviolet.svg?style=flat-square&logo=GNU%20Emacs&logoColor=white)][doomemacs]
[![NixOS Unstable](https://img.shields.io/badge/NixOS-26.11-blue.svg?style=flat-square&logo=NixOS&logoColor=white)](https://nixos.org)

**Hey,** you. You're finally awake. You were trying to configure your OS
declaratively, right? Walked right into that NixOS ambush, same as us, and those
dotfiles over there.

> [!IMPORTANT]
> **Disclaimer:** _This is not a "community framework" or "NixOS distribution"._
> Please do not use it like one. It is an ongoing and haphazard experiment to
> feel out NixOS and the Nix language for my own purposes, and is home to all
> manner of unspeakable, over-engineered hackery that make the other 9 circles
> of hell look like tropical beach resorts.
>
> Until I can bend spoons with my Nix-fu, please divert your Nix(OS) questions
> [to the NixOS discourse][nixos-discourse] instead of my issue tracker. That
> said, I'm more than happy [to hear input and discuss ideas](/discussions), but
> be warned: I'm awful at staying on top of my Github notifications.

(screenshots coming soon)

------

| **Shell:**    | zsh + zpm                      |
| **WM:**       | hyprland + noctalia            |
| **Editor:**   | [Doom Emacs][doomemacs]        |
| **Terminal:** | foot                           |
| **Launcher:** | rofi                           |
| **Browser:**  | librewolf                      |

-----

## Quick start

1. Acquire or build a NixOS 26.11+ image:
   ```sh
   # Yoink nixos-unstable from upstream
   $ wget -O nixos.iso https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso
   ```

2. Write it to a USB drive:
   ```sh
   # Replace /dev/sdX with the correct partition!
   $ cp nixos.iso /dev/sdX
   ```
   
3. Restart and boot into the installer.

4. Do your partitions and mount your root to `/mnt` ([for
   example](hosts/udon/README.org)).

5. Clone these dotfiles somewhere:
   ```sh
   $ git clone --recursive https://github.com/hlissner/dotfiles
   ```
   
6. Create a host config in `hosts/` (see [existing ones](hosts/) for examples).

7. Run the installer as root (the installer's `nixos` user has passwordless
   sudo):
   ```sh
   # The options are optional, but these are their default values:
   $ dotfiles/install.zsh \
         --root /mnt \
         --flake /mnt/etc/dotfiles \
         --host "$HOST" \
         --user hlissner
   ```

8. Then reboot and you're good to go!

> [!WARNING]
> Don't forget to change your `root` and `$USER` passwords! They are set to
> `nixos` by default.


## Management

And I say, `bin/hey`, [what's going on?](https://youtu.be/ZZ5LpwO-An4).

```
SYNOPSIS:
  hey [-?|-??|-???|-!] [-h|--help] COMMAND [ARGS...]

OPTIONS:
  -!
    Do a dry run. WARNING: It's up to called scripts to obey!
  -? | -?? | -???
    Enable debug (verbose) mode, at increasing verbosity.
  -h, --help
    Display the documentation embedded in a target script's header.

COMMANDS:
  - build|b    -- Build nix images, or recompile bin/hey.
  - exec       -- Execute a program on $PATH through hey.
  - gc         -- Garbage collect and optimize the nix store.
  - get|set    -- Alias for hey vars {get,set} ...
  - help|h     -- Display documentation for a command.
  - hook       -- Trigger an event.
  - host       -- Dispatch to hosts/$HOST/bin.
  - info       -- Display information about the current system (JSON).
  - ops        -- Operate on remote HeyOS-powered hosts.
  - path       -- Prints a path to a subarea of my dotfiles.
  - profile|pr -- Operate on the nixos profile.
  - pull       -- Update one of (or all) HeyOS's inputs.
  - reload|re  -- Reload running services.
  - repl       -- Open a nix or janet repl with this flake preloaded.
  - swap|sw    -- Swap nix-store symlinks with mutable copies (and back)
  - sync|s     -- Rebuild this flake (using nixos-rebuild).
  - test       -- Run the Hey and/or Nix test suites.
  - vars       -- Get or set session or persistent state in userspace.
  - which      -- Print a command's path (with arguments) without running it.
  - wm         -- Dispatch to config/$WM/bin.
  - .*         -- Execute the first script found under host, wm, or bin/.
  - ./         -- Execute a script by path.
  - @*         -- Dispatch to config/DIR/bin.
```

## Frequently asked questions

+ **Why NixOS?**

  Because managing a fleet of servers, a hundred strong, is the tenth circle of
  hell without a declarative, generational, and immutable single-source-of-truth
  configuration framework like NixOS.
  
  Sure beats the nightmare of brittle capistrano/chef/puppet/ansible/shell
  scripts I left behind.

+ **Should I use NixOS?**

  **Short answer:** no.
  
  **Long answer:** no really. Don't.
  
  **Long long answer:** I'm not kidding. Don't.
  
  **Unsigned long long answer:** Alright alright. Here's why not:

  - Its learning curve is steep.
  - You _will_ trial and error your way to enlightenment, if you survive the
    frustration long enough.
  - NixOS is unlike other Linux distros. Your issues will be unique and
    difficult to google. A decent grasp of Linux and your chosen services is a
    must, if only to distinguish Nix(OS) issues from Linux (or upstream) issues
    -- as well as to debug them or report them to the correct authority (and
    coherently).
  - If words like "declarative", "generational", and "immutable" don't put your
    sexuality in jeopardy, you're considering NixOS for the wrong reasons.
  - The overhead of managing a NixOS config will rarely pay for itself with 3
    systems or fewer (perhaps another distro with nix on top would suit you
    better?).
  - Official documentation for Nix(OS) is vast, but shallow. Unofficial
    resources and example configs are sparse and tend toward too simple or too
    complex (and most are outdated). Case in point: this repo.
  - The Nix language is obtuse and its toolchain is not intuitive. Your
    experience will be infinitely worse if functional languages are alien to
    you, however, learning Nix is a must to do even a fraction of what makes
    NixOS worth the trouble.
  - If you need somebody else to tell you whether or not you need NixOS, you
    don't need NixOS.

  If you're not discouraged by this, then you didn't need my advice in the first
  place. Stop procrastinating and try NixOS!
  
+ **How do you manage secrets?**

  With [agenix].

+ **Why did you write bin/hey?**

  I envy Guix's CLI and want similar for NixOS, whose toolchain is spread across
  many commands, none of which are as intuitive: `nix`, `nix-collect-garbage`,
  `nixos-rebuild`, `nix-env`, `nix-shell`, etc.
  
  I don't claim `hey` is the answer, but who doesn't like their own brew?

+ **How 2 flakes?**

  Would it be the NixOS experience if I gave you all the answers in one,
  convenient place?
  
  No. Suffer my pain:
  
  - [A three-part tweag article that everyone's read.](https://www.tweag.io/blog/2020-05-25-flakes/)
  - [An overengineered config to scare off beginners.](https://github.com/divnix/devos)
  - [A minimalistic config for scared beginners.](https://github.com/colemickens/nixos-flake-example)
  - [A nixos wiki page that spells out the format of flake.nix.](https://wiki.nixos.org/wiki/Flakes)
  - [Official documentation that nobody reads.](https://nixos.org/learn.html)
  - [Some great videos on general nixOS tooling and hackery.](https://www.youtube.com/channel/UC-cY3DcYladGdFQWIKL90SQ)
  - A couple flake configs that I 
    [may](https://github.com/LEXUGE/nixos) 
    [have](https://github.com/bqv/nixrc)
    [shamelessly](https://git.sr.ht/~dunklecat/nixos-config/tree)
    [rummaged](https://github.com/utdemir/dotfiles)
    [through](https://github.com/purcell/dotfiles).
  - [Some notes about using Nix](https://github.com/justinwoo/nix-shorts)
  - [What helped me figure out generators (for npm, yarn, python and haskell)](https://myme.no/posts/2020-01-26-nixos-for-development.html)
  - [Learn from someone else's descent into madness; this journals his
    experience digging into the NixOS
    ecosystem](https://www.ianthehenry.com/posts/how-to-learn-nix/introduction/)
  - [What y'all will need when Nix drives you to drink.](https://www.youtube.com/watch?v=Eni9PPPPBpg)

  And if all else fails, ask for help on [the NixOS Discourse][nixos-discourse].


[nixos-discourse]: https://discourse.nixos.org
[doomemacs]: https://doomemacs.org
[agenix]: https://github.com/ryantm/agenix
