# packages/hey.nix -- the HeyOS CLI

{ callPackage, ... }:

let janet = callPackage ./_janet.nix {};
in janet.mkJanetBin {
  name = "hey";
  description = "A control center for my dotfiles";
  # modules/hey.nix puts this on JANET_PATH, for the janet scripts hey
  # dispatches to but doesn't compile in.
  passthru = { inherit (janet) janetLibs; };
}
