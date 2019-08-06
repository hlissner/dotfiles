{ config, pkgs, libs, ... }:

let zgen = builtins.fetchGit "https://github.com/tarjoilija/zgen";
in
{
  environment = {
    variables = {
      ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
      ZSH_CACHE = "$XDG_CACHE_HOME/zsh";
      ZGEN_DIR  = "$XDG_CACHE_HOME/zgen";
      ZGEN_SOURCE = "${zgen}/zgen.zsh";
    };

    systemPackages = with pkgs; [
      zsh
      nix-zsh-completions
      fasd
      exa
      fd
      tmux
      htop
      tree
    ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableGlobalCompInit = false; # I'll do it myself
    promptInit = "";
  };

  home-manager.users.hlissner.xdg.configFile = {
    # link recursively so other modules can link files in this folder,
    # particularly in zsh/rc.d/*.zsh
    "zsh" = { source = <config/zsh>; recursive = true; };
  };
}
