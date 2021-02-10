{ lib, stdenv, fetchzip, my, ... }:

stdenv.mkDerivation {
  name = "adl";

  src = fetchzip {
    url = "https://github.com/RaitaroH/adl/archive/master.zip";
    sha256 = "HtKSPD3g0y68A37N4HhOIorW4sPyOr4ei9wABFh4GYc=";
  };

  buildInputs = with my; [
    trackma
    anime-downloader
  ];

  phases = "installPhase";
  installPhase = ''
    mkdir -p $out/bin
    cp $src/adl $out/bin/adl
    cp ${my.trackma}/bin/trackma $out/bin/trackma
    cp ${my.anime-downloader}/bin/anime $out/bin/anime
  '';

  meta = {
    homepage = "https://github.com/RaitaroH/adl";
    description = "popcorn anime-downloader + trackma wrapper";
    license = lib.licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    maintainers = [];
  };
}
