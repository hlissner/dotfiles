{ appimageTools, fetchurl, lib, gsettings-desktop-schemas, gtk3, makeDesktopItem }:

let pname = "FontBase";
    version = "2.10.3";
    desktopItem = makeDesktopItem {
      name = pname;
      desktopName = "FontBase";
      comment = "Font management. Perfected.";
      icon = "fonts";
      terminal = "false";
      exec = pname;
      categories = "Graphics;";
    };
in appimageTools.wrapType2 rec {
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://releases.fontba.se/linux/${pname}-${version}.AppImage";
    sha256 = "1c4xaxlm95sqvn7fqqdkbgnvb12x5wmds5ayx124sxb6mnkfpkq5";
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
    description = "Font management. Perfected.";
    homepage = https://fontba.se/;
    # license = licenses.isc;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ hlissner ];
  };
}
