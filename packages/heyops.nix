# packages/heyops.nix -- hey, but for other HeyOS machines

{ callPackage, ... }:

(callPackage ./_janet.nix {}).mkJanetBin {
  name = "heyops";
  description = "A control center for my other machines";
}
