# packages/psxtract.nix --- PSone Classics (EBOOT.PBP) back into bin/cue
#
# For rebuilding CD tracks in PS1 pkg files.

{ lib, pkgsCross, fetchFromGitHub, python3, writeShellScriptBin, wineWow64Packages, ... }:

let
  exe = pkgsCross.mingw32.stdenv.mkDerivation {
    pname = "psxtract-2";
    version = "0-unstable-2026-07-05";

    src = fetchFromGitHub {
      owner = "has207";
      repo = "psxtract-2";
      rev = "4691fc405698d53927df6e4f59c3e9b113c13706";
      hash = "sha256-pZbYHMPoOjLf8qubIWZ5+OQP44wU6+qMmDcGBRCHuMY=";
    };

    nativeBuildInputs = [ python3 ];
    enableParallelBuilding = true;
    installPhase = "install -Dm755 psxtract.exe $out/bin/psxtract.exe";
  };
in (writeShellScriptBin "psxtract" ''
  # Its own prefix, so it can't trip over (or leave anything in) mine. And no
  # display: it's a GUI-subsystem exe that only stays on the console if it has
  # arguments, and I'd rather it die than open a window from a script.
  export WINEPREFIX="''${XDG_CACHE_HOME:-$HOME/.cache}/psxtract"
  export WINEDEBUG=-all
  export WINEDLLOVERRIDES="winemenubuilder.exe=d;mscoree=d;mshtml=d"
  unset DISPLAY WAYLAND_DISPLAY
  exec ${wineWow64Packages.stable}/bin/wine ${exe}/bin/psxtract.exe "$@"
'') // {
  meta = {
    description = "Decrypts PSone Classics from PSN into bin/cue";
    homepage = "https://github.com/has207/psxtract-2";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "psxtract";
  };
}
