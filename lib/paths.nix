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
}
