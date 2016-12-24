# Henrik's dotfiles
[![MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

<img src="http://i.giphy.com/ZHlGzvZb130nm.gif" align="right" />

My dotfiles. Fuel for my madness. Designed for MacOS, Arch Linux and
the various debian-based boxes I frequently ssh into.

It is organized into topics, some with their own READMEs. Check them out for
more targeted information. The `./boostrap` script is used to install and update
them.

## Bootstrap

`bootstrap` is my idempotent dotfile deployment script.

e.g. `./bootstrap os/arch shell/{zsh,tmux} dev/python`

```
Usage: bootstrap [-iuldynr] [topic1[ topic2[ ...]]]

Options:
  -d  Do a dry run (only output commands, no changes)
  -i  Don't run install scripts
  -l  Don't symlink dotfiles or bin scripts
  -n  Don't overwrite conflicts (no prompts
  -u  Don't run update scripts
  -y  Overwrite conflicts (no prompts)
  -r  Refresh symlinks (same as -uiy)
  -s  Server mode; only install the bare minimum (depends on topic)
```

Here's a simplified break down of what it does:

```bash
# 1. Symlinks topic's bin scripts to ~/.bin
ln -sfv $topic/bin/* ~/.bin/

# 2. Symlinks dotfiles to $HOME
ln -sfv $topic/.* ~/
ln -sfv $topic/.config/* ~/.config/

# 3. Track enabled topics in ~/.dotfiles/.enabled.d.
# 4. If topic is enabled, run its update script. Otherwise, run its install script
if [[ -e ~/.dotfiles/.enabled.d/$topic ]]; then
    $topic/update
else
    ln -sfv $topic ~/.dotfiles/.enabled.d/
    $topic/install
fi
```

## Clean

`clean` will delete broken symlinks in `$HOME`, and can "disable" all topics by removing
their symlinks in `.enabled.d/`.

```
Usage: clean [-du]

Options:
  -d  Do a dry run (only output commands, no changes)
  -u  Uninstall all enabled topics
```

## Other Relevant Configs

+ [Vim](https://github.com/hlissner/.vim) (pulled in by the `editor/vim` topic)
+ [Emacs](https://github.com/hlissner/.emacs.d) (pulled in by the `editor/emacs` topic)
