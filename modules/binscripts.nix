# binscripts.nix --- preloading my binscripts' dependencies
#
# {ba,z}sh scripts are hell to maintain at any level of complexity, so in my
# search for a sane (and high-level) language, I landed on Ruby. I wanted a
# Lisp, but the many implementations I reviewed (e.g. Janet, Common Lisp, scsh
# (Scheme), and babashka (Clojure)) tended toward boilerplate-heavy and
# shell-distant API design. And, more often than not, are slow to cold-start.
#
# Then there's Ruby, an underrated language for this purpose -- or any other,
# besides webdev, thanks to the shadow Rails casts and Ruby's esoteric and
# many-ways-to-do-one-thing syntax.

{ self, lib, pkgs, config, ... }:

with builtins;
with lib;
let cfg = config.modules.binscripts;
in {
  options.modules.binscripts = with self.lib.options; {
    enable = mkBoolOpt true;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = with pkgs; [
        ruby_3_2
        rubyPackages_3_2.sqlite3
        rubyPackages_3_2.thor
        rubyPackages_3_2.rake
      ];
    }

    # For screen capture/selection
    (mkIf config.services.xserver.enable {
      user.packages = with pkgs; [
        ffmpeg_6-full
        slop
        maim
      ];
    })
  ]);
}
