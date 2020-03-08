[
  (self: super: with super; {
    my = {
      ant-dracula = (callPackage ./packages/ant-dracula.nix {});
      cached-nix-shell =
        (callPackage
          (builtins.fetchTarball
            https://github.com/xzfc/cached-nix-shell/archive/master.tar.gz) {});
      emacs27 = (callPackage ./packages/emacs27.nix {});
      linode-cli = (callPackage ./packages/linode-cli.nix {});
      ripcord = (callPackage ./packages/ripcord.nix {});
      zunit = (callPackage ./packages/zunit.nix {});
    };

    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit super;
    };

    # Occasionally, "stable" packages are broken or incomplete, so access to the
    # bleeding edge is necessary, as a last resort.
    unstable = import <nixos-unstable> { inherit config; };
  })

  # emacsGit
  (import (builtins.fetchTarball https://github.com/nix-community/emacs-overlay/archive/master.tar.gz))
]
