{
  description = "A minimal, yet grossly incandescent NixOS config";

  inputs = {
    super.url = "github:hlissner/dotfiles";
  };

  outputs = inputs @ { ... }:
    with dotfiles.lib; mkFlake inputs {
      # Required
      systems = [ "x86_64-linux" "aarch64-linux" ];
      hosts = mapModules ./hosts import;

      # Optional
      profiles = mkProfiles [] ./profiles;
      overlays = mapModules ./overlays import;
      packages = mapModules ./packages import;
    };
};
