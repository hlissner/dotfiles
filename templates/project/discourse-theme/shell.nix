{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [ libffi ruby ];
  shellHook = ''
    mkdir -p .gem
    export GEM_HOME=$PWD/.gem
    export GEM_PATH=$GEM_HOME
    export PATH=$GEM_HOME/bin:$PATH

    if ! command -v discourse_theme >/dev/null; then
      echo "Installing discourse_theme CLI"
      gem install discourse_theme
    fi
  '';
  hardeningDisable = [ "all" ];
}
