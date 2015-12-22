source $HOME/.dotfiles/.common.sh

## Paths
# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

##
export DOCKER_HOST=tcp://server:4243
export RUST_SRC_PATH=$HOME/Dropbox/lib/rust/src
export GOPATH=$HOME/Dropbox/work/go
export ANDROID_HOME=/usr/local/opt/android-sdk
export ANDROID_SDK=/usr/local/Cellar/android-sdk/24.2
export RUBYOPT=rubygems

# OSX Only
if [[ -x /usr/libexec/path_helper ]]; then
    eval $(/usr/libexec/path_helper -s)
fi
path=(
    $DOTFILES/{bin,scripts}
    $HOME/.{rb,py}env/bin
    $HOME/bin
    $GOPATH/bin
    $ANDROID_HOME/platform-tools
    $ANDROID_HOME/tools
    /Library/TeX/texbin
    $path
)

local FUNC_DIR="$DOTFILES/zsh/functions"
fpath=(
  ~/.zsh/completion
  "$FUNC_DIR"
  $fpath
)

# Browser
export BROWSER='open'

# Editors
export EDITOR=$(is-callable nvim && echo 'nvim' || echo 'vim')
export VISUAL=$EDITOR
export PAGER='less'

# export CC=/usr/bin/clang
# export CXX=/usr/bin/clang++
# export CXXFLAGS="-I/usr/local/include"
export C_INCLUDE_PATH="/usr/local/include"
export CPLUS_INCLUDE_PATH="/usr/local/include"
export LIBRARY_PATH="/usr/local/lib"
# export LDFLAGS="-L/usr/local/lib"

export LESS='-F -g -i -M -R -S -w -z-4'
if is-callable lesspipe; then
  export LESSOPEN='| /usr/bin/env lesspipe %s 2>&-'
fi

# Temporary Files
if [[ ! -d "$TMPDIR" ]]; then
  export TMPDIR="/tmp/$USER"
  mkdir -p -m 700 "$TMPDIR"
fi

TMPPREFIX="${TMPDIR%/}/zsh"
[[ ! -d "$TMPPREFIX" ]] && mkdir -p "$TMPPREFIX"

[[ -z "$LANG" ]] && export LANG='en_US.UTF-8'

autoload -U colors && colors
