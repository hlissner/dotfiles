# test/nixos/modules/services/gnome-keyring.nix --- tests for modules/services/gnome-keyring.nix
#
# nixpkgs' niri module turns the keyring on by itself, and gcr-ssh-agent follows
# the keyring, so a niri host picks up gcr without ever touching
# modules.services.gnome-keyring. The upstream assertion that it can't share a
# system with programs.ssh.startAgent is the only thing that fails, and only on
# a host that doesn't also enable the keyring module (soba, 2026-10).

{ evalConfig, lib, ... }:

with lib;
let
  # A niri workstation with sshd, which is what every desktop host amounts to.
  # Nothing here asks for a keyring.
  ws = modules: evalConfig ([{
    modules.wm.desktop = "niri";
    modules.profiles.role = "workstation";
    modules.services.ssh.enable = true;
  }] ++ modules);
  failing = c: map (a: a.message) (filter (a: !a.assertion) c.assertions);

  gcr = ws [];
  nogcr = ws [{ services.gnome.gnome-keyring.enable = mkForce false; }];
in {
  # Where the socket is belongs to nixpkgs; that one is named is what matters.
  testNiriAloneDisablesStartAgent = {
    expr = {
      startAgent = gcr.programs.ssh.startAgent;
      sock = gcr.environment.sessionVariables ? SSH_AUTH_SOCK;
      failing = failing gcr;
    };
    expected = { startAgent = false; sock = true; failing = []; };
  };

  testNoGcrKeepsStartAgent = {
    expr = {
      startAgent = nogcr.programs.ssh.startAgent;
      sock = nogcr.environment.sessionVariables ? SSH_AUTH_SOCK;
    };
    expected = { startAgent = true; sock = false; };
  };
}
