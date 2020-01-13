{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "0.8.2";
  pname = "zunit";

  src = fetchurl {
    url = "https://github.com/zunit-zsh/zunit/releases/download/v${version}/zunit";
    sha256 = "1bmp3qf14509swpxin4j9f98n05pdilzapjm0jdzbv0dy3hn20ix";
  };

  phases = "installPhase";

  installPhase = ''
    outdir=$out/share/zunit
    mkdir -p $outdir
    cp $src $outdir/antigen.zsh
  '';

  meta = {
    description = "ZUnit is a powerful unit testing framework for ZSH";
    homepage = https://zunit.xyz/;
    license = stdenv.lib.licenses.mit;
  };
}
