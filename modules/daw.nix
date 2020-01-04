# I make music for my games. LMMS is my DAW. Fruityloops too, on my Windows
# system, but I'm slowly phasing it out for open-source alternatives. When I'm
# in the mood for a quick chiptune, I fire up sunvox instead -- it runs
# absolutely anywhere, even on my ipad and phone.

{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    audacity   # for recording and remastering audio
    # lmms     # for making music
    sunvox     # for making music (where LMMS is overkill)

    # Build our own LMMS because the built-in nixpkg is broken, due to a 'Could
    # not find the Qt platform plugin "xcb" in ""' error on startup:
    # https://github.com/NixOS/nixpkgs/issues/76074
    (callPackage <packages/lmms.nix> {})
  ];
}
