export GOPATH="$XDG_DATA_HOME/go:$HOME/work/go"

# Adds $GOPATH/bin's to PATH
path=( `printf '%s/bin\n' ${(@s/:/)GOPATH}` $path )
