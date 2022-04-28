{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    # nodejs-12.x
    # nodejs-14.x
    # nodejs-16.x
    nodejs-latest
    yarn
    typescript-language-server
  ];
  shellHook = ''
    export NPM_CONFIG_USERCONFIG = "$PWD/.npm/config";
    export NPM_CONFIG_CACHE      = "$PWD/.npm/cache";
    export NPM_CONFIG_TMP        = "$PWD/.npm/tmp";
    export NPM_CONFIG_PREFIX     = "$PWD/.npm/config";
    export NODE_REPL_HISTORY     = "$PWD/.npm/node/repl_history";
    export PATH = [ "$(${pkgs.yarn}/bin/yarn global bin)" ];
  '';
}
