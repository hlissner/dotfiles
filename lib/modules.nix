{ lib, attrs }:

let
  inherit (builtins) attrValues readDir pathExists concatLists;
  inherit (lib) id mapAttrsToList filterAttrs hasPrefix hasSuffix nameValuePair removeSuffix;
in rec {
  mapModules = dir: fn:
    attrs.mapFilterAttrs'
      (n: v:
        let path = "${toString dir}/${n}"; in
        if v == "directory" && pathExists "${path}/default.nix"
        then nameValuePair n (fn path)
        else if v == "regular" &&
                n != "default.nix" &&
                n != "flake.nix" &&
                hasSuffix ".nix" n
        then nameValuePair (removeSuffix ".nix" n) (fn path)
        else nameValuePair "" null)
      (n: v: v != null && !(hasPrefix "_" n))
      (readDir dir);

  mapModules' = dir: fn:
    attrValues (mapModules dir fn);

  # dir -> fn :: attrs (attrs (attrs ...))
  #
  # Creates a file tree where each leaf is the result of FN.
  mapModulesRec = dir: fn:
    attrs.mapFilterAttrs'
      (n: v:
        let path = "${toString dir}/${n}"; in
        if v == "directory"
        then nameValuePair n (mapModulesRec path fn)
        else if v == "regular" &&
                n != "default.nix" &&
                n != "flake.nix" &&
                hasSuffix ".nix" n
        then nameValuePair (removeSuffix ".nix" n) (fn path)
        else nameValuePair "" null)
      (n: v: v != null && !(hasPrefix "_" n))
      (readDir dir);

  # dir -> fn :: listOf paths
  #
  # Returns a list of all files under DIR, mapped by FN.
  mapModulesRec' = dir: fn:
    let
      dirs =
        mapAttrsToList
          (k: _: "${dir}/${k}")
          (filterAttrs
            (n: v: v == "directory"
                   && !(hasPrefix "_" n)
                   && !(pathExists "${dir}/${n}/.noload"))
            (readDir dir));
      files = attrValues (mapModules dir id);
      paths = files ++ concatLists (map (d: mapModulesRec' d id) dirs);
    in map fn paths;

  # dir :: attrs
  #
  # TODO
  mapHosts = dir:
    mapModules dir (path: {
      inherit path;
      config = import path;
    });
}
