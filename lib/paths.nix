{ self, lib, ... }:

with builtins;
with lib;
rec {
  # ...
  dotFiles   = toString ../.;
  modulesDir = "${dotFiles}/modules";
  configDir  = "${dotFiles}/config";
  binDir     = "${dotFiles}/bin";
  themeDir   = "${modulesDir}/themes";
  homeDir = "/home/${let name = getEnv "USERNAME"; in
                     if elem name [ "" "root" ]
                     then "hlissner" else name}";
}
