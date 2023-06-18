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
    rev = "175cada7bc85c6c26ae7de07717cff0f6da82d93";
    sha256 = "1yqv4qz1c3pymjd3h4n5h0bdvpqqvb30d9kbwmdkihhdrl75xbi9";
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
