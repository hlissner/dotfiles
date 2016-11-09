# Henrik's dotfiles
[![MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

<img src="http://i.giphy.com/ZHlGzvZb130nm.gif" align="right" />

These are my dotfiles. They fuel my madness. Designed for MacOS, Arch Linux and the
various debian-based boxes I frequently ssh into.

My dotfiles are organized into "topics". The `./boostrap` script is used to install or
update them.

+ `bootstrap install [topic1 topic2 ...]`: symlinks topics to `./.enabled.d` and
  dotfiles therein to $HOME (then runs $topic/install)
+ `bootstrap update`: updates (enabled) topics that have a $topic/update script
+ `bootstrap clean`: deletes dead symlinks in $HOME
+ Each command has a one-letter shortcut: `./bootstrap i os/macos`

Or use one of my recipes:

+ `bootstrap install recipes/ganymede` (my laptop)

A few good-to-knows (where $topic is an enabled topic):

+ zshrc auto-sources `$topic/*.zsh`
+ `$topic/bin` is added to PATH
+ `$topic/.*` (starts with a dot) is symlinked to $HOME

## Relevant

+ [Vim config](https://github.com/hlissner/.vim)
+ [Emacs config](https://github.com/hlissner/.emacs.d)
