{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [ ruby deno ];
  shellHook = ''
    mkdir -p .gem
    export GEM_HOME=$PWD/.gem
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH
  '';
}
