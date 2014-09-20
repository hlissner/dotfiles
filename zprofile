# Executes commands at login pre-zshrc.

# Browser
[[ "$OSTYPE" == darwin* ]] && export BROWSER='open'

## Editors
export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'
export RUBYOPT=rubygems

## Language
if [[ -z "$LANG" ]]; then
  export LANG='en_US.UTF-8'
fi

## Paths
# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the list of directories that Zsh searches for programs.
path=(
  $HOME/.{py,rb}env/bin
  $HOME/.dotfiles/bin
  /usr/local/{bin,sbin}
  /usr/{bin,sbin}
  /{bin,sbin}
)
[[ "$OSTYPE" == darwin* ]] && path+="/usr/X11/bin"

fpath=(
  $HOME/.zsh/functions
  $fpath
)

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-X -F -g -i -M -R -S -w -z-4'

# Set the Less input preprocessor.
if (( $+commands[lesspipe.sh] )); then
  export LESSOPEN='| /usr/bin/env lesspipe.sh %s 2>&-'
fi

# Temporary Files
if [[ ! -d "$TMPDIR" ]]; then
  export TMPDIR="/tmp/$USER"
  mkdir -p -m 700 "$TMPDIR"
fi

TMPPREFIX="${TMPDIR%/}/zsh"
[[ ! -d "$TMPPREFIX" ]] && mkdir -p "$TMPPREFIX"
