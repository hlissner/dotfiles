[![MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat-square)](./LICENSE)

# Henrik's dotfiles

<img src="http://i.giphy.com/ZHlGzvZb130nm.gif" align="right" />

Fuel for my madness. Designed for Arch Linux, MacOS, and various remotes I
frequent.

It is organized into topics, some with their own READMEs. Check them out for
more targeted information. The `./bootstrap` script is used to deploy and update
them.

## Bootstrap

`bootstrap` is my idempotent dotfile deployment script.

e.g. `./bootstrap os/+arch shell/+{zsh,tmux} dev/+pyenv`

```
Usage: bootstrap [-iuldypLSU] [topic1[ topic2[ ...]]]

Options:
  -i  Don't run install scripts
  -u  Don't run update scripts
  -l  Don't symlink dotfiles
  -d  Do a dry run (only output commands, no changes)
  -y  Overwrite conflicts (no prompts)
  -p  Prompt on file conflict (to overwrite)
  -L  Refresh links; the same as -ui
  -S  Server mode; only install the bare minimum
  -U  Update mode; run update scripts only
```

Here's a simplified break down of what it does:

```bash
# 1. Symlinks dotfiles to $HOME
ln -sfv $topic/.* ~/
ln -sfv $topic/.{config,local}/* ~/.{config,local}/

# 2. Track enabled topics in ~/.dotfiles/.enabled.d.
if [[ -e ~/.dotfiles/.enabled.d/$topic ]]; then
    # 3a. If topic is already enabled, run update script
    $topic/update
else
    # 3b. Otherwise, run install script
    ln -sfv $topic ~/.dotfiles/.enabled.d/
    $topic/install
fi
```

## Clean

`clean` deletes broken symlinks in `$HOME`. If passed `-u`, it will remove all
symlinks in `.enabled.d/`, marking all topics as "disabled".

```
Usage: clean [-du]

Options:
  -d  Do a dry run (only output commands, no changes)
  -u  Uninstall all enabled topics
```

## Other Relevant Configs

+ [Vim](https://github.com/hlissner/.vim) (pulled in by the `editor/vim` topic)
+ [Emacs](https://github.com/hlissner/.emacs.d) (pulled in by the `editor/emacs` topic)
