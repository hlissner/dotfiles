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
    "zsh" = {
      source = <config/zsh>;
      recursive = true;
    };
  };
}
