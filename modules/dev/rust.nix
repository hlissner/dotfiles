{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rustup
    rls
  ];

  home.xdg.configFile = {
    "zsh/rc.d/aliases.rust.zsh".source = <config/rust/aliases.zsh>;
    "zsh/rc.d/env.rust.zsh".source = <config/rust/env.zsh>;
  };
}
