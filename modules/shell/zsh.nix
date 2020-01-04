{ config, pkgs, libs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      zsh
      nix-zsh-completions
      fasd
      bat
      exa
      fd
      fzf
      tmux
      htop
      tree
      tldr
    ];
    variables = {
      ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
      ZSH_CACHE = "$XDG_CACHE_HOME/zsh";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableGlobalCompInit = false; # I'll do it myself
    promptInit = "";
  };

  home.xdg.configFile = {
    # link recursively so other modules can link files in this folder,
    # particularly in zsh/rc.d/*.zsh
    "zsh" = {
      source = <config/zsh>;
      recursive = true;
    };
  };
}
