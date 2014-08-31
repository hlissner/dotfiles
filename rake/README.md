# Rake install scripts

I use global rakefiles to provision my computers and servers. They
work for OSX and Ubuntu; a `rake -g -T` will reveal all the available
options.

Running `rake -g update` will run the rake task that matches your
computer's hostname; they can be found in
`rake/nodes/<hostname>.rake`. I have one for each of my computers.

Feel free to take from it what you like.

## Packages

This currently provides:

* Homebrew
* OSX settings
* Zsh + zprezto -- deploys my [zsh dotfiles](http://github.com/hlissner/dotfiles)
* Emacs (mac only) -- deploys my [emacs.d](http://github.com/hlissner/emacs.d)
* Vim -- deploys my [vimrc](https://github.com/hlissner/dotfiles/blob/master/vimrc)
* Pyenv
* Rbenv

Planned features:

* Gitlab
* Flexget seedbox
* Webserver stacks for vagrant

## Installation

Simply symlink `./rake` to `~/.rake`, then these commands will become
accessible globally via `rake -g [task]`.

```sh
git clone https://github.com/hlissner/dotfiles ~/.dotfiles
ln -sf ~/.dotfiles/rake ~/.rake
```

Or just cd into `./rake` and work from there.

## Usage

```sh
rake -g                  # Same as: rake -g setup:`hostname`
rake -g update           # Same as: rake -g setup:`hostname`

# This will install all the things specified in
# rake/nodes/<hostname>.rake and/or update them if already installed.
rake -g setup:<hostname>

# Installs <package>, or updates it
rake -g pkg:<package>
# Package sub-commands
rake -g pkg:<package>:install
rake -g pkg:<package>:remove
rake -g pkg:<package>:update

rake -g destroy          # Runs pkg:*:remove and deletes all packages
```

A couple examples:

```sh
# Install/update homebrew, zsh and emacs
rake -g pkg:homebrew
rake -g pkg:zsh
rake -g pkg:emacs

# Install/update my config for ganymede
rake -g setup:ganymede
```
