# modules/dev/unity3d.nix --- https://unity.com
#
# I don't use Unity often, but when I do, it's in a team or with students.

{ pkgs, ... }:
{
  my.packages = with pkgs; [
    unity3d
  ];
}
