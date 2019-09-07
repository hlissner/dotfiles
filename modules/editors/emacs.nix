{ config, lib, pkgs, ... }:

let unstable = import <nixpkgs-unstable> {};
in
{
  environment.systemPackages = with pkgs; [
    (lib.mkIf (config.programs.gnupg.agent.enable) pinentry_emacs)

    editorconfig-core-c
    (ripgrep.override {withPCRE2 = true;})
    # Doom Emacs + dependencies
    unstable.emacs
    sqlite                          # :tools (lookup +docsets)
    texlive.combined.scheme-medium  # :lang org -- for latex previews
    ccls                            # :lang (cc +lsp)
    nodePackages.javascript-typescript-langserver # :lang (javascript +lsp)
  ];

  fonts.fonts = [ pkgs.emacs-all-the-icons-fonts ];

  home-manager.users.hlissner.xdg.configFile = {
    "zsh/rc.d/aliases.emacs.zsh".source = <config/emacs/aliases.zsh>;
    "zsh/rc.d/env.emacs.zsh".source = <config/emacs/env.zsh>;
  };
}
