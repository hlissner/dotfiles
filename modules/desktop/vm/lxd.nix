# Inspired by https://www.srid.ca/2012301.html

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.vm.lxd;
in {
  options.modules.desktop.vm.lxd = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    virtualisation.lxd.enable = true;

    user.packages = [
      (pkgs.writeScriptBin "lxc-build-nixos-image" ''
        #!/usr/bin/env nix-shell
        #!nix-shell -i bash -p nixos-generators
        set -xe
        config=$1
        metaimg=`nixos-generate -f lxc-metadata \
          | xargs -r cat \
          | awk '{print $3}'`
        img=`nixos-generate -c $config -f lxc \
          | xargs -r cat \
          | awk '{print $3}'`
        lxc image import --alias nixos $metaimg $img
      '')
    ];
  };
}
