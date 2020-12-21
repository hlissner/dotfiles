{ pkgs ? import <nixpkgs> {} }:

with pkgs;
let nixBin =
      writeShellScriptBin "nix" ''
          ${nixFlakes}/bin/nix --option experimental-features "nix-command flakes" "$@"
      '';
in mkShell {
  buildInputs = [
    git
    gnupg
    nix-zsh-completions
  ];
  shellHook = ''
    export DOTFILES="$(pwd)"
    export PATH="$DOTFILES/bin:${nixBin}/bin:$PATH"
  '';
}
