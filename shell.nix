{ self,
  mkShell,
  callPackage,
  git,
  janet,
  jpm,
  nix-zsh-completions,
  nix-tree,
  nix-diff,
  nvd,
  nix-output-monitor,
  nix-inspect,
  ... }:

let janetTree = (callPackage ./packages/_janet.nix {}).janetTree;
in mkShell {
  buildInputs = [
    git
    janet
    jpm
    self.judge
    nix-zsh-completions
    nix-tree
    nix-diff
    nvd
    nix-output-monitor
    nix-inspect
  ];
  # Gotchas:
  # - jpm ignores JANET_{MOD,BIN,MAN}PATH once JANET_TREE is set.
  # - JANET_PATH last entry has highest precedence (then the rest are searched
  #   in order).
  # - jpm install builds a local build (in ./build) and won't affect the global
  #   install.
  # - `jpm {build,install}` is incremental. It won't build anything that hasn't
  #   changed. Use `jpm clean` to force it.
  shellHook = ''
    root=$(git rev-parse --show-toplevel)
    export NIX_CONFIG=$(printf '%s\nwarn-dirty = false' "''${NIX_CONFIG-}")
    export DOTFILES_HOME="$root"
    export JANET_TREE="$root/build/jpm_tree"
    export JANET_BUILDPATH="$root/build"
    mkdir -p "$JANET_TREE"  # jpm's own mkdir of it isn't -p
    export JANET_BINPATH="$JANET_TREE/bin"
    export JANET_PATH="$root/lib:${janetTree}/lib:$JANET_TREE/lib"
    export PATH="$JANET_BINPATH:$root/bin:$PATH"
    # What hey would hand nix, so nixosConfigurations evaluates without it.
    host=''${HOST:-$(cat /etc/hostname)}
    export HEYENV=$(printf '{"path":"%s","user":"%s","host":"%s"}' "$root" "$USER" "$host")

    if [[ $- == *i* ]]; then
      # No NIX_CONFIG for this: flake commands force pure-eval unless told
      # --impure on the command line, pure-eval = false or not.
      alias nrepl='nix repl --impure'
      alias neval='nix eval --impure'
      alias nbuild='nix build --impure'
      alias install='jpm install'
      alias clean='jpm clean'
      rebuild() { jpm clean; jpm install; }
      cat <<EOF
    Some ways to explore this flake:

      nrepl .                       then nixosConfigurations.$host.{config,options,pkgs}
      neval .#nixosConfigurations.$host.config.OPTION
      nbuild .#nixosConfigurations.$host.config.system.build.toplevel
      nvd diff /run/current-system result    what that build would change
      nix build .#hey               packages, checks: no --impure needed
      nix-inspect -p .              browse all of it as a tree
      nix-tree /run/current-system  who pulls in what and how big
      nix flake show                everything the flake exports

    For bin/hey:
      install                       same as jpm install
      clean                         same as jpm clean
      rebuild                       same as jpm clean+install
    EOF
      if [[ -x build/hey ]]; then
        echo
        hey version
      fi
    fi
    unset JANET_HEADERPATH JANET_LIBPATH root host
  '';
}
