# modules/dev --- common settings for dev modules

{ pkgs, ... }:
{
  my.packages = with pkgs; [
    gnumake
  ];
}
