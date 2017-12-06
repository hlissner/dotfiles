# Mein dotfiles

A tidy `$HOME` is a tidy mind.

![Oct-2017 Screenshot of Arch Linux](assets/screenshots/OCT2017.png)

These are my dotfiles, designed primarily for Arch Linux, MacOS and debian. They
are my specific breed of madness, split into 2-level topics (e.g. `shell/zsh`)
that strive for minimum `$HOME` presence (adhering to XDG standards where
possible).

+ wm: bspwm
+ shell: zsh
+ font: kakwafont
+ bar: polybar

## Quick start

`bash <(curl -s https://raw.githubusercontent.com/hlissner/dotfiles/master/bootstrap.sh)`

## Overview

```sh
# general
bin/       # global scripts
assets/    # wallpapers, sounds, screenshots, etc

# categories
base/      # provisions my system with the bare essentials
dev/       # relevant to software development & programming in general
editor/    # configuration for my text editors
misc/      # for various apps & tools
shell/     # shell utilities, including zsh + bash
```

## Dotfile management

```
Usage: deploy [-acdlLit] [TOPIC...]

  -a   Target all enabled topics (ignores TOPIC args)
  -c   Afterwards, remove dead symlinks & empty dot-directories in $HOME.
       Can be used alone.
  -d   Unlink and run `./_init clean` for topic(s)
  -l   Only relink topic(s) (implies -i)
  -L   List enabled topics
  -i   Inhibit install/update/clean init scripts
  -t   Do a test run; do not actually do anything
```

e.g.
+ `deploy base/arch shell/{zsh,tmux}`: enables base/arch, shell/zsh & shell/tmux
+ `deploy -d shell/zsh`: disables shell/zsh & cleans up after it
+ `deploy -l shell/zsh`: refresh links for shell/zsh (inhibits init script)
+ `deploy -l`: relink all enabled topics
+ `deploy -L`: list all enabled topics

Here's a breakdown of what the script does:

``` sh
cd $topic
if [[ -L $DOTFILES_DATA/${topic//\//.}.topic ]]; then
    ./_init update
else
    ln -sfv $DOTFILES/$topic $DOTFILES_DATA/${topic//\//.}.topic

    ./_init install
    ./_init link
fi
```

## Relevant projects

+ [DOOM Emacs](https://github.com/hlissner/doom-emacs) (pulled by `editor/emacs`)
+ [My vim config](https://github.com/hlissner/.vim) (pulled by `editor/{neo,}vim`)
