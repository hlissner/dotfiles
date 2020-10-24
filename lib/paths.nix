{ self, lib, ... }:

with builtins;
with lib;
rec {
  # ...
  dotFilesDir = toString ../.;
  modulesDir  = "${dotFilesDir}/modules";
  configDir   = "${dotFilesDir}/config";
  binDir      = "${dotFilesDir}/bin";
  themesDir   = "${modulesDir}/themes";
  homeDir = "/home/${let name = getEnv "USERNAME"; in
                     if elem name [ "" "root" ]
                     then "hlissner" else name}";
}
