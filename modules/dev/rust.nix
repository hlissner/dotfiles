{ config, lib, pkgs, ... }:
{
  my = {
    packages = with pkgs; [
      rustup
      rustfmt
      rls
    ];

    env.RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
    env.CARGO_HOME = "$XDG_DATA_HOME/cargo";
    env.PATH = [ "$CARGO_HOME/bin" ];

    alias.rs  = "rustc";
    alias.rsp = "rustup";
    alias.ca  = "cargo";

    setup = ''
      ${pkgs.rustup}/bin/rustup update nightly
      ${pkgs.rustup}/bin/rustup default nightly
    '';
  };
}
