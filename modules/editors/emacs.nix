# Emacs is my main driver. I'm the author of Doom Emacs
# <https://github.com/hlissner/doom-emacs>. This module sets it up to meed my
# particular Doomy needs.

{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Doom dependencies
    emacs
    git
    (ripgrep.override {withPCRE2 = true;})
    # Optional dependencies
    editorconfig-core-c # per-project style config
    fd                  # faster projectile indexing
    imagemagick         # for image-dired
    gnutls              # for TLS connectivity
    (lib.mkIf (config.programs.gnupg.agent.enable)
      pinentry_emacs)   # in-emacs gnupg prompts
    zstd                # for undo-tree compression
    ffmpeg              # for screen recording emacs
    # Module dependencies
    sqlite                          # :tools (lookup +docsets)
    texlive.combined.scheme-medium  # :lang org -- for latex previews
    ccls                            # :lang (cc +lsp)
    nodePackages.javascript-typescript-langserver # :lang (javascript +lsp)
    rls                             # :lang (rust +lsp)
  ];

  fonts.fonts = [
    pkgs.emacs-all-the-icons-fonts
  ];

  home.xdg.configFile = {
    "zsh/rc.d/aliases.emacs.zsh".source = <config/emacs/aliases.zsh>;
    "zsh/rc.d/env.emacs.zsh".source = <config/emacs/env.zsh>;
  };
}
