# packages/pkg2zip.nix --- unpack PSN pkgs (Vita, PSP, PSone Classics)
#
# Not in nixpkgs. Uses lusid1's fork (still maintained), which includes
# rif2zrif, which turns work.bin into the zRIF string pkg2zip wants for Vita
# games.

{ lib, stdenv, fetchFromGitHub, python3, ... }:

stdenv.mkDerivation {
  pname = "pkg2zip";
  version = "2.6-unstable-2026-08-04";

  src = fetchFromGitHub {
    owner = "lusid1";
    repo = "pkg2zip";
    rev = "6ee3df57eef2521ff38542a70500794937974180";
    hash = "sha256-Us9JPNSh6Pl6Ivv1120oyzr+kkvsmY1bv7G1WTOg22c=";
  };

  buildInputs = [ python3 ];
  enableParallelBuilding = true;

  installPhase = ''
    install -Dm755 pkg2zip $out/bin/pkg2zip
    install -Dm755 rif2zrif.py $out/bin/rif2zrif
  '';

  meta = {
    description = "Decrypts PS Vita, PSP and PSX pkgs, into a zip or onto disk";
    homepage = "https://github.com/lusid1/pkg2zip";
    license = lib.licenses.unlicense;
    mainProgram = "pkg2zip";
  };
}
