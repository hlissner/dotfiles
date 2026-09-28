# test/nixos/modules/agenix.nix --- tests for modules/agenix.nix
#
# Two things pure evaluation took away, and what stands in for them: the shared
# secrets.nix is found through the store snapshot (self.configDir) rather than
# the live checkout, and the host key is checked at activation instead of by an
# assertion that pathExists could never satisfy.

{ evalConfig, evalConfig', mkHey, lib, ... }:

with lib;
let
  dir = toString ./agenix.d;
  withSecrets = evalConfig' (mkHey { inherit dir; }) [];
  withoutSecrets = evalConfig [];
  scriptOf = s: if isString s then s else s.text;
in {
  # secrets.nix is imported while nix evaluates, so it has to come off the
  # snapshot DIR stands in for. Through a live path it would be a quiet
  # pathExists = false under pure evaluation, and no secrets at all.
  testSharedSecretsComeOffTheSnapshot = {
    expr = mapAttrs (_: s: { inherit (s) file owner; }) withSecrets.age.secrets;
    expected.foo = { file = "${dir}/config/secrets/foo.age"; owner = "nobody"; };
  };

  testHostKeyIsCheckedAtActivationNotEval = {
    expr = {
      script = hasInfix withSecrets.modules.agenix.hostKey
                 (scriptOf withSecrets.system.activationScripts.agenixHostKey);
      # The old assertion pathExists'd the key, and a check build is exactly
      # where that's false; nothing may fail now that secrets are declared.
      failed = map (a: a.message) (filter (a: !a.assertion) withSecrets.assertions);
      idle = withoutSecrets.system.activationScripts ? agenixHostKey;
    };
    expected = { script = true; failed = []; idle = false; };
  };
}
