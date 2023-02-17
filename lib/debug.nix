{ lib, ... }:

with builtins;
with lib;
rec {
  inspect = fn: val:
    traceSeqN 10 (fn val) val;
}
