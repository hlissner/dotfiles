# https://github.com/nix-community/emacs-overlay is all about Emacs HEAD and
# pkgs.emacs is all about stable, but I want 27.0.90 with its native JSON
# library, and none of HEAD's instability, so...

{ stdenv, pkgs, lib, fetchurl, ... }:

pkgs.emacsGit.overrideAttrs (oa: rec {
  name = "emacs-${version}";
  version = "27.0.90";
  src = fetchurl {
    url = "https://alpha.gnu.org/gnu/emacs/pretest/${name}.tar.xz";
    sha256 = "1x0z9hfq7n88amd32714g9182nfy5dmz9br0pjqajgq82vjn9qxk";
  };
  buildInputs = oa.buildInputs ++ [ pkgs.jansson ];
  configureFlags = oa.configureFlags ++ [ "--with-jansson" ];

  # Remove tramp-detect-wrapped-gvfsd.patch because it doesn't work with 27.0.90
  patches = lib.drop 1 oa.patches;
})
