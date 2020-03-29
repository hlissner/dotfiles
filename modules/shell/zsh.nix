# modules/shell/zsh.nix --- ...

{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.shell.zsh = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.zsh.enable {
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

      alias.exa = "exa --group-directories-first";
      alias.l   = "exa -1";
      alias.ll  = "exa -lg";
      alias.la  = "LC_COLLATE=C exa -la";
      alias.sc = "systemctl";
      alias.ssc = "sudo systemctl";

      # Write it recursively so other modules can write files to it
      home.xdg.configFile."zsh" = {
        source = <config/zsh>;
        recursive = true;
      };
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      # I init completion myself, because enableGlobalCompInit initializes it too
      # soon, which means commands initialized later in my config won't get
      # completion, and running compinit twice is slow.
      enableGlobalCompInit = false;
      promptInit = "";
    };

    system.userActivationScripts.cleanupZgen = ''
      rm -fv $XDG_CACHE_HOME/zsh/*
    '';
  };
}
