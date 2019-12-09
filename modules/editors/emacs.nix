{ config, lib, pkgs, ... }:

let unstable = import <nixpkgs-unstable> {};
in
{
  environment.systemPackages = with pkgs; [
    (lib.mkIf (config.programs.gnupg.agent.enable) pinentry_emacs)

    zstd
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
    # Avoid "emacs" because Emacs HEAD respects XDG conventions and we're only
    # using this directory to store extra zsh config for my nix dotfiles.
    "emacscfg" = { source = <config/emacs>; recursive = true; };
  };
}
