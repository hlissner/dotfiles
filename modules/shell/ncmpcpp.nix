{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (ncmpcpp.override { visualizerSupport = true; })
  ];

  home-manager.users.hlissner.xdg.configFile = {
    "zsh/rc.d/aliases.ncmpcpp.zsh".source = <config/ncmpcpp/aliases.zsh>;
    "zsh/rc.d/env.ncmpcpp.zsh".source = <config/ncmpcpp/env.zsh>;
    "ncmpcpp/config".source = <config/ncmpcpp/config>;
    "ncmpcpp/bindings".source = <config/ncmpcpp/bindings>;
  };
}
