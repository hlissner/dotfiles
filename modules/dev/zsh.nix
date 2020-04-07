# modules/dev/zsh.nix --- http://zsh.sourceforge.net/
#
# Shell script programmers are strange beasts. Writing programs in a language
# that wasn't intended as a programming language. Alas, it is not for us mere
# mortals to question the will of the ancient ones. If they want shell programs,
# they get shell programs.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.dev.zsh = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.dev.zsh.enable {
    my.packages = with pkgs; [
      shellcheck
      my.zunit
    ];
  };
}
