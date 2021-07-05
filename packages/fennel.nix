{ lib, stdenv, luajit, my, ... }:

let name = "fennel";
    version = "0.9.2";
in stdenv.mkDerivation {
  inherit name version;

  src = fetchTarball {
    url = "https://fennel-lang.org/downloads/${name}-${version}.tar.gz";
    sha256 = "0p9zr2vb9gq877advb5jvybx6dmqzmxqh4i7yzdr7fwvz7xzd2jv";
  };

  buildInputs = [
    luajit
  ];

  phases = "installPhase";
  installPhase = ''
    mkdir -p $out $out/bin
    cp $src/fennel $out/bin/fennel
    cp $src/fennel.lua $out/fennel.lua
    chmod +x $out/bin/fennel
    sed -i 's%^#!/usr/bin/env lua$%#!${luajit}/bin/luajit%' $out/bin/fennel
  '';

  meta = {
    homepage = "https://github.com/bakpakin/Fennel";
    description = "Lua Lisp Language";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    maintainers = [];
  };
}
