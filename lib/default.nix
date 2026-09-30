{ lib
, pkgs ? throw "this lib has no package set; use self.lib from a host"
, ...
}:

let
  inherit (builtins) intersectAttrs functionArgs foldl';
  inherit (lib) attrsToList attrValues recursiveUpdate;

  # mapModules gets special treatment because it's needed early!
  inherit (modules) mapModules;
  modules = import ./modules.nix { inherit lib; };

  # I embrace the callPackage pattern for lib/*.nix modules. I.e. Their
  # arguments are dynamically passed as they are loaded, drawn from a running
  # list of loaded lib/*.nix modules (plus the nixpkgs 'lib' passed to this
  # module and the whole set altogether).
  libConcat = a: b: a // {
    ${b.name} =
      b.value (intersectAttrs (functionArgs b.value) (a // { inherit lib pkgs; }));
  };
  libModules = mapModules ./. import;
  libs = foldl' libConcat { inherit lib pkgs; self = libs; } (attrsToList libModules);
in
  # The flattened tree makes the namespaced endpoints optional, and namespaces
  # stay useful for inherit'ed let-bindings.
  libs // (foldl' recursiveUpdate {} (attrValues libs))
