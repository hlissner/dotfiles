# test/nixos/hosts.nix --- tests for hosts/
#
# Every live host in hosts/ is applied and evaluated here, without $HEYENV and
# without --impure: evalHost fabricates the `hey` argument and routes the host
# through the same mkHostModules that mkFlake uses.
#
# One test, on purpose. Forcing system.build.toplevel down to its derivation
# path drags the whole configuration through evaluation -- assertions, type
# checks, unbound variables and all -- without building anything, and that is
# the check that catches real breakage. Everything else about a host is either
# visible the moment it boots or a deliberate choice this file shouldn't be
# re-litigating.

{ evalHost', hosts, lib, ... }:

with lib;
let
  # Hosts that cannot be evaluated right now, quarantined rather than guessed
  # at when the fix needs a hardware decision the test suite cannot make.
  broken = [ ];

  # modules/agenix.nix asserts that its host key exists whenever a host
  # declares any secrets, using builtins.pathExists on an absolute path outside
  # the store, which pure evaluation cannot see. Emptying age.secrets instead
  # would dodge the assertion, but hosts reference their secrets by name
  # (config.age.secrets.foo.path), so a dummy key it is.
  buildable =
    mapAttrs (evalHost' [{ modules.agenix.hostKey = builtins.toFile "host_ed25519" ""; }])
             (removeAttrs hosts broken);
in {
  testEveryHostEvaluates = {
    expr = mapAttrs (_: c: isString c.system.build.toplevel.drvPath) buildable;
    expected = mapAttrs (_: _: true) buildable;
  };
}
