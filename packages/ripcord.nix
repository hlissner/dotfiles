{ appimageTools, fetchurl, lib, gsettings-desktop-schemas, gtk3, makeDesktopItem }:

let pname = "ripcord";
    version = "0.4.21";
    desktopItem = makeDesktopItem {
      name = pname;
      desktopName = "Ripcord";
      comment = "Desktop chat client for Slack (and Discord)";
      icon = "discord";
      terminal = "false";
      exec = pname;
      categories = "Network;InstantMessaging;";
    };
in appimageTools.wrapType2 rec {
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://cancel.fm/dl/Ripcord-${version}-x86_64.AppImage";
    sha256 = "63a16a1369bc9c6d7b24c12044e3d2e341264f65ac38bd16bf01576f6cceb3df";
  };

  profile = ''
    export LC_ALL=C.UTF-8
    export XDG_DATA_DIRS=${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}:$XDG_DATA_DIRS
  '';

  multiPkgs = null; # no 32bit needed
  extraPkgs = p: (appimageTools.defaultFhsEnvArgs.multiPkgs p);

  extraInstallCommands = ''
    mv $out/bin/{${name},${pname}}
    chmod +x $out/bin/${pname}
    mkdir -p "$out/share/applications/"
    cp "${desktopItem}"/share/applications/* "$out/share/applications/"
    substituteInPlace $out/share/applications/*.desktop --subst-var out
  '';

  meta = with lib; {
    description = "Desktop chat client for Slack (and Discord)";
    homepage = https://cancel.fm/ripcord;
    license = licenses.isc;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ hlissner ];
  };
}
