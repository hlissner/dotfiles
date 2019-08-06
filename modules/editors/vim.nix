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

  home-manager.users.hlissner.xdg.configFile = {
    "zsh/rc.d/aliases.vim.zsh".source = <config/vim/aliases.zsh>;
  };
}
