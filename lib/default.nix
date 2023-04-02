{ self, lib, pkgs, ... }:

let
  inherit (builtins) mapAttrs intersectAttrs functionArgs getEnv fromJSON;
  inherit (lib) attrValues foldr foldl;

  # mapModules gets special treatment because it's needed early!
  inherit (attrs) attrsToList mergeAttrs';
  inherit (modules) mapModules;
  attrs   = import ./attrs.nix   { inherit lib; };
  modules = import ./modules.nix { inherit lib attrs; };

  /* Given an attrset of nix module partials, returns it as a sorted list of
     NameValuePairs according to its callPackage-style dependencies from the
     rest of the list.

     sortLibsByDeps :: AttrSet -> [ AttrSet ... ]

     Example:
       sortLibsByDeps { libA = { libB, ... }: {}; libB = { ... }: { [...] }; }
       => [ { libB = {...}: [...]; } { libA = { libB, ...}: [...]; } ]
  */
  sortLibsByDeps = modules:
    modules;

    # TODO
    # let
    #   dependsOn = a: b:
    #     elem a (attrByPath b [] deps);
    #   maybeSortedAttrs = toposort dependsOn (diskoLib.deviceList devices);
    # in
    #   if (hasAttr "cycle" maybeSortedAttrs) then
    #     abort "detected a cycle in your disk setup: ${maybeSortedAttrs.cycle}"
    #   else
    #     maybeSortedAttrs.result;

  # I embrace the callPackage pattern for lib/*.nix modules. I.e. Their
  # arguments are dynamically passed as they are loaded, drawn from a running
  # list of loaded lib/*.nix modules (plus the nixpkgs 'lib' passed to this
  # module and the whole set altogether).
  libConcat = a: b: a // {
    ${b.name} = b.value (intersectAttrs (functionArgs b.value) a);
  };
  # FIXME: Lexicographical loading can cause race conditions. Sort them?
  libModules = sortLibsByDeps (mapModules ./. import);
  libs = foldl libConcat { inherit lib pkgs; self = libs; } (attrsToList libModules);
in
  # The flattened tree is appended to make the namespaced endpoints optional,
  # and because namespaces are useful for inherit'ed let-bindings. In other
  # words: lib.attrsToList == lib.attrs.attrsToList.
  libs // (mergeAttrs' (attrValues libs))
