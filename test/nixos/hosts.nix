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

  # modules/agenix.nix asserts that /etc/ssh/host_ed25519 exists whenever a
  # host declares any secrets, using builtins.pathExists on an absolute path
  # outside the store. Pure evaluation cannot see that file, so the assertion
  # fails for every host with a secrets/ directory. Emptying age.secrets
  # satisfies the assertion's own escape hatch (`age.secrets == {} || ...`)
  # and is narrower than mkForce'ing the whole assertion list.
  buildable =
    mapAttrs (evalHost' [{ age.secrets = mkForce {}; }])
             (removeAttrs hosts broken);
in {
  testEveryHostEvaluates = {
    expr = mapAttrs (_: c: isString c.system.build.toplevel.drvPath) buildable;
    expected = mapAttrs (_: _: true) buildable;
  };
}
