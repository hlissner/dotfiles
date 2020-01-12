{ config, pkgs, libs, ... }:

{
  imports = [ ./tmux.nix ];

  my = {
    packages = with pkgs; [
      zsh
      nix-zsh-completions
      bat
      exa
      fasd
      fd
      fzf
      htop
      tldr
      tree
    ];
    env.ZDOTDIR   = "$XDG_CONFIG_HOME/zsh";
    env.ZSH_CACHE = "$XDG_CACHE_HOME/zsh";

    home.xdg.configFile."zsh" = { source = <my/config/zsh>; recursive = true; };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableGlobalCompInit = false; # I'll do it myself
    promptInit = "";
  };
}
