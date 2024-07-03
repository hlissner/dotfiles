# rofi-blocks: a plugin for Rofi that enables more dynamic interaction between
# Rofi's state and an arbitrary process. It's not on nixpkgs so...

{ self, lib, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
, json-glib
, rofi-unwrapped
, pango
, glib
, cairo
, gobject-introspection
, wrapGAppsHook }:

stdenv.mkDerivation rec {
  name = "rofi-blocks";

  src = fetchFromGitHub {
    owner = "OmarCastro";
    repo = name;
    rev = "1708f2cb50e593e06cc22eedeecbb4b41584668d";
    sha256 = "0rg007iwws4x6057y28rrkfm931z75x82prms3jzk8q14xxlvvcc";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    gobject-introspection
    wrapGAppsHook
  ];

  buildInputs = [
    rofi-unwrapped
    pango
    glib
    cairo
    json-glib
  ];

  patches = [ ./0001-Patch-plugindir-to-output.patch ];

  meta = with lib; {
    description = "Control rofi content through an external process.";
    homepage = "https://github.com/OmarCastro/rofi-blocks";
    license = licenses.gpl3;
    maintainers = [];
    platforms = with platforms; linux;
  };
}
