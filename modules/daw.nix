# modules/music.nix
#
# I make music for my games. LMMS is my DAW; or will be, once I've weened myself
# off of Fruityloops. When I'm in the mood for a quicky I fire up sunvox
# instead. It runs absolutely anywhere, even on my ipad and phone. As if I'd
# ever need to.

{ config, lib, pkgs, ... }:
{
  my.packages = with pkgs; [
    audacity   # for recording and remastering audio
    sunvox     # for making music (where LMMS is overkill)

    # lmms on stable is broken due to 'Could not find the Qt platform plugin
    # "xcb" in ""' error: https://github.com/NixOS/nixpkgs/issues/76074
    unstable.lmms   # for making music
  ];
}
