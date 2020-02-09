{ stdenv, fetchurl, gtk-engine-murrine }:

stdenv.mkDerivation rec {
  pname = "ant-dracula-theme";
  version = "1.3.0";

  src = fetchurl {
    url = "https://github.com/EliverLara/Ant-Dracula/releases/download/v${version}/Ant-Dracula.tar";
    sha256 = "00b8w69xapqy8kc7zqwlfz1xpld6hibbh35djvhcnd905gzzymkd";
  };

  propagatedUserEnvPkgs = [
    gtk-engine-murrine
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/themes/Ant-Dracula
    cp -a * $out/share/themes/Ant-Dracula
    rm -r $out/share/themes/Ant-Dracula/{Art,LICENSE,README.md,gtk-2.0/render-assets.sh}
    runHook postInstall
  '';

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "1ns00y1haxm20jak26gjv53yisaw9vsr2dbsgj10zz65rglr1h18";

  meta = with stdenv.lib; {
    description = "A flat and light theme with a modern look";
    homepage = https://github.com/EliverLara/Ant-Dracula;
    license = licenses.gpl3;
    platforms = platforms.all;
    maintainers = [
      maintainers.pbogdan
    ];
  };
}
