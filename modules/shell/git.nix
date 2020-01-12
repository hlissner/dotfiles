{ config, lib, pkgs, ... }:

{
  my = {
    packages = with pkgs; [
      gitAndTools.hub
      gitAndTools.diff-so-fancy
    ];
    zsh.rc = lib.readFile <my/config/git/aliases.zsh>;
    # Do recursively, in case git stores files in this folder
    home.xdg.configFile = {
      "git/config".source = <my/config/git/config>;
      "git/ignore".source = <my/config/git/ignore>;
    };
  };
}
