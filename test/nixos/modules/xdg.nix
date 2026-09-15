# test/nixos/modules/xdg.nix --- tests for modules/xdg.nix
#
# Only the ssh half. None of what it does can fail a build: a binary that falls
# out of the wrapper list still works, it just quietly goes back to ~/.ssh, and
# an identity named in ssh_config that isn't on disk is a "no such identity"
# line on every connection rather than an error. So the suite pins the shape.

{ evalConfig, lib, ... }:

with lib;
let
  on = evalConfig [{ modules.xdg.ssh.enable = true; }];

  pkgsNamed = name: filter (p: (p.name or "") == name) on.environment.systemPackages;
  wrapper = head (pkgsNamed "openssh-wrapped");
  wraps = prog: hasInfix ''wrapProgram "$out/bin/${prog}"'' wrapper.buildCommand;
in {
  # Every one of these execs the ssh *it* was built against, not the one on
  # $PATH, so falling off this list means falling back to ~/.ssh entirely.
  # openssh ships an ssh-copy-id of its own, and in system-path its symlink
  # beats a separate ssh-copy-id-wrapped derivation -- which is how that
  # wrapper spent however long being built and never once being run.
  testEverySshLikeIsWrappedInPlace = {
    expr = {
      unwrapped = filter (prog: !(wraps prog))
        [ "ssh" "scp" "sftp" "ssh-add" "ssh-copy-id" "ssh-keygen" ];
      shadowed = pkgsNamed "ssh-copy-id-wrapped";
    };
    expected = { unwrapped = []; shadowed = []; };
  };

  # The wrapper stats each key before offering it, so ssh is never told about
  # one that isn't there. An IdentityFile back in ssh_config is read by the
  # wrapped binaries too (~/.config/ssh/config Includes it), so it would undo
  # all of that.
  testSystemConfigNamesNoIdentities = {
    expr = filter (hasInfix "IdentityFile ~/.config/ssh/id_")
                  (splitString "\n" on.programs.ssh.extraConfig);
    expected = [];
  };
}
