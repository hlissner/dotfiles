{ lib, stdenv, luajit, my, ... }:

let name = "fennel";
    version = "0.8.1";
in stdenv.mkDerivation {
  inherit name version;

  src = fetchTarball {
    url = "https://fennel-lang.org/downloads/${name}-${version}.tar.gz";
    sha256 = "0hzxnsgq4yqsvzkndplcllvq3j8cw45npqyrqa2ww8jv5abr183i";
  };

  buildInputs = [
    luajit
  ];

  phases = "installPhase";
  installPhase = ''
    mkdir -p $out/bin
    cp $src/fennel $out/bin/fennel
    chmod +x $out/bin/fennel
    sed -i 's%^#!/usr/bin/env lua$%#!${luajit}/bin/lua%' $out/bin/fennel
  '';

  meta = {
    homepage = "https://github.com/bakpakin/Fennel";
    description = "Lua Lisp Language";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = [];
  };
}
