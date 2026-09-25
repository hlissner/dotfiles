# packages/judge.nix -- the test runner behind `hey test hey`

{ callPackage, ... }:

(callPackage ./_janet.nix {}).judge
