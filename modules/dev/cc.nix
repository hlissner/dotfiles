# modules/dev/cc.nix --- C & C++
#
# I love C. I tolerate C++. I adore C with a few choice C++ features tacked on.
# Liking C/C++ seems to be an unpopular opinion. It's my guilty secret, so don't
# tell anyone pls.

{ config, options, lib, pkgs, ... }:
with lib;
{
  options.modules.dev.cc = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.dev.cc.enable {
    my.packages = with pkgs; [
      clang
      gcc
      bear
      gdb
      cmake
      llvmPackages.libcxx
    ];
  };
}
