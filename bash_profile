# set 256 color profile where possible
if [[ $COLORTERM == gnome-* && $TERM == xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM=xterm-256color
fi


## Bash rcfiles ###########################

source $HOME/.dotfiles/.common.sh

declare -a paths=(
    "$DOTFILES/{bin,scripts}"
    "$HOME/.{rb,py}env/{shims,bin}"
    "/usr/local/{bin,sbin}"
)
[[ "$OSTYPE" == "darwin"* ]] && paths+="$(brew --prefix coreutils)/libexec/gnubin"

for index in ${!paths[*]}; do
    [ -d ${paths[$index]} ] && PATH="${paths[$index]}:$PATH"
done
unset paths
export PATH


## Bash rcfiles ###########################

cache rbenv init - --no-rehash
cache pyenv init - --no-rehash
is-interactive && cache fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install
is-callable tmuxifier && is-interactive && cache tmuxifier init -

iload bash/fzf
load  bash/aliases
load  bash/config
iload bash/prompt
