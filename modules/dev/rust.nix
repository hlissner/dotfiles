# modules/dev/rust.nix --- https://rust-lang.org
#
# Oh Rust. The light of my life, fire of my loins. Years of C++ has conditioned
# me to believe there was no hope left, but the gods have heard us. Sure, you're
# not going to replace C/C++. Sure, your starlight popularity has been
# overblown. Sure, macros aren't namespaced, cargo bypasses crates.io, and there
# is no formal proof of your claims for safety, but who said you have to solve
# all the world's problems to be wonderful?

{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.rust;
in {
  options.modules.dev.rust = {
    enable = mkBoolOpt false;
    enableGlobally = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.enableGlobally {
      user.packages = [ pkgs.rustup ];

      env.PATH = [ "$(${pkgs.yarn}/bin/yarn global bin)" ];
    })

    {
      env.RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
      env.CARGO_HOME = "$XDG_DATA_HOME/cargo";
      env.PATH = [ "$CARGO_HOME/bin" ];

      environment.shellAliases = {
        rs  = "rustc";
        rsp = "rustup";
        ca  = "cargo";
      };
    }
  ]);
}
