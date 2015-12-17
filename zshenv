is-callable() { (( $+commands[$1] )) || (( $+functions[$1] )) || (( $+aliases[$1] )); }
is-mac() { [[ "$OSTYPE" == "darwin"* ]]; }
is-deb() { [[ "$OSTYPE" == "linux-gnu" ]]; }
is-cygwin() { [[ "$OSTYPE" == "cygwin"* ]]; }

# Browser
export BROWSER='open'

## Editors
export EDITOR=$(is-callable nvim && echo 'nvim' || echo 'vim')
export VISUAL=$EDITOR
export PAGER='less'
export RUBYOPT=rubygems
# export CC=/usr/bin/clang
# export CXX=/usr/bin/clang++
# export CXXFLAGS="-I/usr/local/include"
export C_INCLUDE_PATH="/usr/local/include"
export CPLUS_INCLUDE_PATH="/usr/local/include"
export LIBRARY_PATH="/usr/local/lib"
# export LDFLAGS="-L/usr/local/lib"

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

##
export DOCKER_HOST=tcp://server:4243

export RUST_SRC_PATH=$HOME/Dropbox/lib/rust/src
export GOPATH=$HOME/Dropbox/work/go
export ANDROID_HOME=/usr/local/opt/android-sdk
export ANDROID_SDK=/usr/local/Cellar/android-sdk/24.2

# basictex
# export PATH=/usr/local/texlive/2015basic/bin/x86_64-darwin:$PATH

# Set the list of directories that Zsh searches for programs.
path=(
  $HOME/.dotfiles/{bin,scripts}
  /usr/local/{bin,sbin}
  /usr/{bin,sbin}
  /{bin,sbin}
  $HOME/.{rb,py}env/bin
  $GOPATH/bin
  $ANDROID_HOME/platform-tools
  $ANDROID_HOME/tools
  /Library/TeX/texbin
  $path
)

local FUNC_DIR="$HOME/.dotfiles/zsh/functions"
fpath=(
  ~/.zsh/completion
  "$FUNC_DIR"
  $fpath
)

# Load all scripts from ./zsh/functions/*
for func in "$FUNC_DIR"/*(N-.x:t); do
    autoload -Uz $func
done
