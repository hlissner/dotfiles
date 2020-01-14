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

    # Write it recursively so other modules can write files to it
    home.xdg.configFile."zsh" = {
      source = <my/config/zsh>;
      recursive = true;
    };

    alias.exa = "exa --group-directories-first";
    alias.l   = "exa -1";
    alias.ll  = "exa -l";
    alias.la  = "LC_COLLATE=C exa -la";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableGlobalCompInit = false; # I'll do it myself
    promptInit = "";
  };
}
