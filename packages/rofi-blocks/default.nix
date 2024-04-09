# rofi-blocks: a plugin for Rofi that enables more dynamic interaction between
# Rofi's state and an arbitrary process. It wasn't maintained at the time I
# looked into it, so I forked it and made a bunch of changes. It now powers the
# Ruby UI library I'm cooking up in my dotfiles.

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
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  name = "rofi-blocks";

  src = fetchFromGitHub {
    owner = "hlissner";
    repo = name;
    rev = "f784a6786ea5c4e4e9db505389b32723f8f0aff9";
    sha256 = "0vkf75aryr75x22v6z3yn87vschh3xb0f7h2g72p466lixrdfi70";
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
    homepage = "https://github.com/hlissner/rofi-blocks";
    license = licenses.gpl3;
    maintainers = [];
    platforms = with platforms; linux;
  };
}
