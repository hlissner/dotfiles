#
# ~/.bash_profile
#

# set 256 color profile where possible
if [[ $COLORTERM == gnome-* && $TERM == xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM=xterm-256color
fi


## Bash rcfiles ###########################

source $HOME/.dotfiles/shell/common.sh

PATH="$DOTFILES/bin:/usr/local/{bin,sbin}:$PATH"
for bin in "$ENABLED_DIR"/*/bin; do
    [[ -e "$bin" ]] && PATH="$bin:$PATH"
done
PATH="$HOME/bin:$PATH"
export PATH


## Bash rcfiles ###########################

load shell/+bash/config.bash

cache rbenv init - --no-rehash
cache pyenv init - --no-rehash
if is-interactive; then
    cache fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install
    cache tmuxifier init -
    load shell/+bash/prompt.bash
fi

# Done!
