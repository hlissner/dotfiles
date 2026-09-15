# test/nixos/modules/apps/term/foot.nix --- tests for modules/apps/term/
#
# term.default is a separate option from term.foot.enable: one picks the
# terminal, the other installs it. What's pinned is the two places that choice
# has to reach, neither of which complains when it doesn't.

{ evalConfig, lib, ... }:

{
  testTerminalFollowsTermDefault = {
    expr = map
      (t: (evalConfig [{ modules.apps.term.default = t; }]).environment.sessionVariables.TERMINAL)
      [ "xterm" "foot" ];
    expected = [ "xterm" "foot" ];
  };

  # foot overrides tmux's terminal with mkForce, so even an explicit definition
  # elsewhere loses. Pinned because mkDefault would look identical in every
  # test that does not try to override it.
  testFootForcesTmuxTerm = {
    expr = (evalConfig [{
      modules.apps.term.foot.enable = true;
      modules.shell.tmux.term = "screen-256color";
    }]).modules.shell.tmux.term;
    expected = "foot";
  };
}
