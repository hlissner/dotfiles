{ appimageTools, fetchurl, lib, gsettings-desktop-schemas, gtk3, makeDesktopItem }:

let pname = "lmms";
    version = "1.2.1";
    desktopItem = makeDesktopItem {
      name = pname;
      desktopName = "LMMS";
      comment = "Cross-platform music production software";
      icon = "lmms";
      terminal = "false";
      exec = pname;
      categories = "Audio";
    };
in appimageTools.wrapType2 rec {
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://github.com/LMMS/lmms/releases/download/v${version}/${name}-linux-x86_64.AppImage";
    sha256 = "0aa63c3fv84wrny7vp7ycdvapp21j09kllzs1xybb19wdkdd863v";
  };

  profile = ''
    export LC_ALL=C.UTF-8
    export XDG_DATA_DIRS=${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${gtk3}/share/gsettings-schemas/${gtk3.name}:$XDG_DATA_DIRS
  '';

  extraPkgs = p: (appimageTools.defaultFhsEnvArgs.multiPkgs p);
  extraInstallCommands = ''
    mv $out/bin/{${name},${pname}}
    chmod +x $out/bin/${pname}
    mkdir -p "$out/share/applications/"
    cp "${desktopItem}"/share/applications/* "$out/share/applications/"
    substituteInPlace $out/share/applications/*.desktop --subst-var out
  '';

  meta = with lib; {
    description = "Cross-platform music production software";
    homepage = https://lmms.io;
    license = licenses.gpl2Plus;
    platforms = [ "x86_64-linux" "i686-linux" ];
    maintainers = with maintainers; [ hlissner ];
  };
}
