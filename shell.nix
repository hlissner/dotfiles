{ mkShell, writeShellScriptBin, nixVersions, git, nix-zsh-completions, ... }:

let nixConfig = builtins.toFile "nix.conf" ''
      warn-dirty = false
      http2 = true
      experimental-features = nix-command flakes
      use-xdg-base-directories = true
    '';
in mkShell {
  buildInputs = [
    git
    nix-zsh-completions
    nixVersions.nix_2_19
  ];
  shellHook = ''
    export NIX_USER_CONF_FILES="${nixConfig}"
    export PATH="$(pwd)/bin:$PATH"
  '';
}
