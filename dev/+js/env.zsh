export NVM_DIR="$HOME/.nvm"

# [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

# Sourcing nvm.sh adds a noticable slow-down on startup, so we scan for
# the current version's path ourselves.
# NOTE This assumes you use the `node` nvm alias, e.g. `nvm install node`
npmpaths=( $HOME/.nvm/versions/node/*/bin(On) )
path=("${npmpaths[1]}" $path)
