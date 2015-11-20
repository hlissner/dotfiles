# Executes commands at login pre-zshrc.

# Browser
export BROWSER='open'

## Editors
export EDITOR='vim'
export VISUAL='vim'
export PAGER='less'
export RUBYOPT=rubygems
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
export CPPFLAGS="-I/usr/local/include"
export LDFLAGS="-L/usr/local/lib"

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-X -F -g -i -M -R -S -w -z-4'

# Set the Less input preprocessor.
if (( $+commands[lesspipe] )); then
  export LESSOPEN='| /usr/bin/env lesspipe %s 2>&-'
fi

# Temporary Files
if [[ ! -d "$TMPDIR" ]]; then
  export TMPDIR="/tmp/$USER"
  mkdir -p -m 700 "$TMPDIR"
fi

TMPPREFIX="${TMPDIR%/}/zsh"
[[ ! -d "$TMPPREFIX" ]] && mkdir -p "$TMPPREFIX"

## Language
[[ -z "$LANG" ]] && export LANG='en_US.UTF-8'

## Paths
# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the list of directories that Zsh searches for programs.
path=(
  /usr/local/{bin,sbin}
  /usr/{bin,sbin}
  /{bin,sbin}
)

fpath=(
  ~/.zsh/completion
  $fpath
)
