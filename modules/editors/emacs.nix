# Emacs is my main driver. I'm the author of Doom Emacs
# https://github.com/hlissner/doom-emacs. This module sets it up to meet my
# particular Doomy needs.

{ config, lib, pkgs, ... }:
{
  my = {
    packages = with pkgs; [
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
    ];

    env.PATH = [ "$HOME/.emacs.d/bin" ];
    zsh.rc = lib.readFile <my/config/emacs/aliases.zsh>;

    # My emacs config is too stateful to manage with nix
    init = ''
      if [ ! -d "$HOME/.emacs.d" ]; then
        ${pkgs.git}/bin/git clone https://github.com/hlissner/doom-emacs "$HOME/.emacs.d"
      fi
      if [ ! -d "$XDG_CONFIG_HOME/doom" ]; then
        ${pkgs.git}/bin/git clone https://github.com/hlissner/doom-emacs-private "$XDG_CONFIG_HOME/doom"
      fi
    '';
  };

  fonts.fonts = [
    pkgs.emacs-all-the-icons-fonts
  ];
}
