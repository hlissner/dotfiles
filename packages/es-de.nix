# packages/es-de.nix --- ES-DE, from upstream's AppImage
#
# nixpkgs dropped es-de in 2025-10 over FreeImage CVEs. The AppImage bundles
# fixes for those and everything else it needs, so use that. The sandbox it runs
# in binds every top-level dir but /nix, which is how /media reaches it.

{ lib, appimageTools, fetchurl, ... }:

appimageTools.wrapType2 rec {
  pname = "es-de";
  version = "3.5.0";

  src = fetchurl {
    url = "https://gitlab.com/api/v4/projects/es-de%2Femulationstation-de/packages/generic/ES-DE_Stable/${version}/ES-DE_x64.AppImage";
    hash = "sha256-q8KZmhI4X4V3W9P5hvqJHHa2nfN5H3wS5MeDzzw2MPU=";
  };

  extraInstallCommands =
    let contents = appimageTools.extract { inherit pname version src; };
    in ''
      install -Dm444 ${contents}/org.es_de.frontend.desktop -t $out/share/applications
      install -Dm444 ${contents}/org.es_de.frontend.svg -t $out/share/icons/hicolor/scalable/apps
    '';

  meta = {
    description = "Frontend for browsing and launching games from emulators";
    homepage = "https://es-de.org/";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "es-de";
  };
}
