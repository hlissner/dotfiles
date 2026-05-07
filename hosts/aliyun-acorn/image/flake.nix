{
  description = "Alibaba Cloud ECS importable image for aliyun-acorn";

  inputs.dotfiles.url = "path:../../..";

  outputs = { dotfiles, ... }:
    let
      imageSystem = "x86_64-linux";
      exposedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      aliyunImage =
        (dotfiles.nixosConfigurations.aliyun-acorn.extendModules {
          modules = [
            ({ modulesPath, lib, ... }: {
              imports = [
                "${modulesPath}/virtualisation/disk-image.nix"
              ];

              image = {
                baseName = "nixos-aliyun-acorn";
                format = "qcow2";
                efiSupport = true;
              };

              virtualisation.diskSize = lib.mkDefault 8192;
            })
          ];
        }).config.system.build.image;
      packageSet = {
        aliyun-image = aliyunImage;
        default = aliyunImage;
      };
    in {
      packages = builtins.listToAttrs (map (system: {
        name = system;
        value = packageSet;
      }) exposedSystems);

      checks.${imageSystem}.aliyun-image = aliyunImage;
    };
}
