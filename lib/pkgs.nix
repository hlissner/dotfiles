# lib/pkgs.nix --- helpers that need a package set
#
# Decorates nixpkgs with extra functions, providing the two builders my modules
# reach for often enough to be worth a name. Modules get at them through hey.lib
# (flattened) or hey.lib.pkgs (namespaced).

{ lib, pkgs, ... }:

let
  inherit (builtins) hashString;
  inherit (lib) head optionalAttrs toList;
in {
  # mkWrapper :: (derivation | listOf derivation) -> string -> derivation
  #
  # Joins PACKAGE, or every derivation in a list of them, into one output that
  # POSTBUILD can wrapProgram. The result is named after the first package.
  mkWrapper = package: postBuild:
    let paths = toList package;
        first = head paths;
    in pkgs.symlinkJoin {
      inherit paths postBuild;
      name = "${first.pname or first.name}-wrapped";
      buildInputs = [ pkgs.makeWrapper ];
    };

  # mkLauncherEntry :: string -> attrs -> derivation
  #
  # A desktop entry for TITLE, meant for a launcher rather than an application
  # menu. The file name is a hash of the title and the command, so two entries
  # that differ in only one of them still get separate files.
  mkLauncherEntry = title: {
      prefix ? "launcher-",
      description ? "",
      icon,
      exec,
      categories ? []
    }: pkgs.makeDesktopItem ({
      inherit icon exec categories;
      name = "${prefix}${hashString "md5" "${title}\n${exec}"}";
      desktopName = title;
    } // optionalAttrs (description != "") {
      genericName = description;
    });
}
