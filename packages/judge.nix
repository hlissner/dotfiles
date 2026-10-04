# packages/judge.nix -- the test runner behind `hey test hey`

{ callPackage, ... }:

(callPackage ./hey/janet.nix {}).judge
