function is-callable {
    which "$1" > /dev/null
}

# set 256 color profile where possible
if [[ $COLORTERM == gnome-* && $TERM == xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM=gnome-256color
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM=xterm-256color
fi


#### Other Settings #########################################

source ~/.bash/path
source ~/.bash/aliases
source ~/.bash/config
source ~/.bash/prompt
