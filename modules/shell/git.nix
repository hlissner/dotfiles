{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gitAndTools.hub
    gitAndTools.diff-so-fancy
  ];

  home-manager.users.hlissner.xdg.configFile = {
    "git/config".source = <config/git/config>;
    "git/ignore".source = <config/git/ignore>;
    "zsh/rc.d/aliases.git.zsh".source = <config/git/aliases.zsh>;
  };
}
