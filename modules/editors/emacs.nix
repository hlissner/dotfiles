# Emacs is my main driver. I'm the author of Doom Emacs
# https://github.com/hlissner/doom-emacs. This module sets it up to meet my
# particular Doomy needs.

{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.my;
let cfg = config.modules.editors.emacs;
    configDir = config.dotfiles.configDir;
in {
  options.modules.editors.emacs = {
    enable = mkBoolOpt false;
    doom = {
      enable  = mkBoolOpt true;
      fromSSH = mkBoolOpt false;
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];

    user.packages = with pkgs; [
      ## Emacs itself
      binutils       # native-comp needs 'as', provided by this
      emacsPgtkGcc   # 28 + pgtk + native-comp

      ## Doom dependencies
      git
      (ripgrep.override {withPCRE2 = true;})
      gnutls              # for TLS connectivity

      ## Optional dependencies
      fd                  # faster projectile indexing
      imagemagick         # for image-dired
      (mkIf (config.programs.gnupg.agent.enable)
        pinentry_emacs)   # in-emacs gnupg prompts
      zstd                # for undo-fu-session/undo-tree compression

      ## Module dependencies
      # :checkers spell
      (aspellWithDicts (ds: with ds; [
        en en-computers en-science
      ]))
      # :checkers grammar
      languagetool
      # :tools editorconfig
      editorconfig-core-c # per-project style config
      # :tools lookup & :lang org +roam
      sqlite
      # :lang cc
      ccls
      # :lang javascript
      nodePackages.javascript-typescript-langserver
      # :lang latex & :lang org (latex previews)
      texlive.combined.scheme-medium
      # :lang beancount
      beancount
      fava
      # :lang rust
      rustfmt
      unstable.rust-analyzer
    ];

    env.PATH = [ "$XDG_CONFIG_HOME/emacs/bin" ];

    modules.shell.zsh.rcFiles = [ "${configDir}/emacs/aliases.zsh" ];

    fonts.fonts = [ pkgs.emacs-all-the-icons-fonts ];

    # init.doomEmacs = mkIf cfg.doom.enable ''
    #   if [ -d $HOME/.config/emacs ]; then
    #      ${optionalString cfg.doom.fromSSH ''
    #         git clone git@github.com:hlissner/doom-emacs.git $HOME/.config/emacs
    #         git clone git@github.com:hlissner/doom-emacs-private.git $HOME/.config/doom
    #      ''}
    #      ${optionalString (cfg.doom.fromSSH == false) ''
    #         git clone https://github.com/hlissner/doom-emacs $HOME/.config/emacs
    #         git clone https://github.com/hlissner/doom-emacs-private $HOME/.config/doom
    #      ''}
    #   fi
    # '';
  };
}
