# Henrik's dotfiles
[![MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

These are the dotfiles that fuel my madness, made for MacOS, Arch Linux and the various
debian-based boxes I frequently ssh into.

## Getting started

`./bootstrap` does everything, including install packages and symlink dotfiles. Pass it
the modules you want. e.g.

`./bootstrap install os/arch vcs/* shell/zsh`

To update all modules:

`./bootstrap update`

Or to clear out all your symlinked dotfilse:

`./bootstrap clean`

Each command has a one-letter shortcut, e.g. `./bootstrap i os/macos`

## Relevant

+ [Hammerspoon config](https://github.com/hlissner/.hammerspoon)
+ [Vim config](https://github.com/hlissner/.vim)
+ [Emacs config](https://github.com/hlissner/.emacs.d)
