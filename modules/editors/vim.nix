{ config, lib, pkgs, ... }:

{
  environment = {
    sessionVariables = {
      EDITOR = "nvim";
      VIMINIT = "let \\$MYVIMRC='\\$XDG_CONFIG_HOME/nvim/init.vim' | source \\$MYVIMRC";
    };

    systemPackages = with pkgs; [
      editorconfig-core-c
      neovim
    ];
  };
}
