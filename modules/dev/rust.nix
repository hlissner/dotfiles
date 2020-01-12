{ config, lib, pkgs, ... }:

{
  my = {
    packages = with pkgs; [ rustup ];
    env.CARGO_HOME = "$XDG_DATA_HOME/cargo";
    env.RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
    env.PATH = [ "$CARGO_HOME/bin" ];
  };
}
