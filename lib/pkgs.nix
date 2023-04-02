# lib/pkgs.nix --- TODO
#
# TODO

{ self, lib, pkgs, ... }:

with builtins;
with lib;
rec {
  mkWrapper = package: postBuild:
    let name = if isList package then elemAt package 0 else package;
        paths = if isList package then package else [ package ];
    in pkgs.symlinkJoin  {
      inherit paths postBuild;
      name = "${name}-wrapped";
      buildInputs = [ pkgs.makeWrapper ];
    };

  mkLauncherEntry = title: {
      prefix ? "launcher-",
      description ? "",
      icon,
      exec,
      categories ? []
    }: pkgs.makeDesktopItem ({
      inherit icon exec categories;
      name = "${prefix}${hashString "md5" exec}";
      desktopName = title;
    } // (if description != "" then {
      genericName = description;
    } else {}));
}
