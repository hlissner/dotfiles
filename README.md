# Henrik's dotfiles
[![MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

<img src="http://i.giphy.com/ZHlGzvZb130nm.gif" align="right" />

My dotfiles. Fuel for my madness. Designed for MacOS, Arch Linux and
the various debian-based boxes I frequently ssh into.

It is organized into topics, some with their own READMEs. Check them out for
more targeted information. The `./boostrap` script is used to install and update
them.

## Bootstrap

`bootstrap` is my idempotent dotfile deployment script. This is how it works:

You pass the directories of "topics" you want to install and it will:

1. symlink `$topic/bin/*` to `~/.bin/`
2. symlink `$topic/.*` to `~/` _and_ `$topic/.*/*` to `~/.$1/` (i.e. 2-level
   symlinking). e.g.  `os/arch/.Xresources` will be symlinked to
   `~/.Xresources`, and `os/arch/.config/redshift.conf` will be symlinked to
   `~/.config/redshift.conf` (`~/.config` is not a symlink).
3. run `$topic/install` the first time
4. run `$topic/update` on consecutive runs
5. symlink `$topic` to `$DOTFILES/.enabled.d/` to keep track of what's enabled.
   Running `bootstrap` without arguments will run this process on all
   enabled topics in `.enabled.d/`.

> NOTE: Be sure to add ~/.bin to PATH

```
Usage: bootstrap [-iuldyn] [topic1[ topic2[ ...]]]

Options:
  -d  Do a dry run (only output commands, no changes)
  -i  Don't run install scripts
  -l  Don't symlink dotfiles or bin scripts
  -n  Don't overwrite conflicts (no prompts
  -u  Don't run update scripts
  -y  Overwrite conflicts (no prompts)
```

Or write a recipe list (examples in `recipes/`):

+ `bootstrap $(recipes/ganymede)` (my laptop)

To update the topics that you've already enabled, simply run `bootstrap`, and it
will update your symlinks and run `$topic/update` wherever they may exist.

A few good-to-knows (where $topic is an enabled topic):

+ zshrc auto-sources `$topic/*.zsh`
+ `$topic/bin/*` scripts will be symlinked to `~/.bin`. The included bash/zsh
  topics add `~/.bin` to `PATH`.

## Clean

`clean` will delete broken symlinks in `$HOME`, and can "disable" topics by
removing their symlinks in `.enabled.d/`

```
Usage: clean [-du]

Options:
  -d  Do a dry run (only output commands, no changes)
  -u  Uninstall all enabled topics
```

## Relevant

+ [Vim config](https://github.com/hlissner/.vim)
+ [Emacs config](https://github.com/hlissner/.emacs.d)
