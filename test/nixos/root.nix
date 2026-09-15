# test/nixos/root.nix --- tests for ./default.nix, the root module
#
# default.nix imports all of modules/, declares the `user` alias, and sets the
# universal defaults every host inherits. Only the alias is tested: the
# defaults are one-liners whose absence is obvious on first use. The naming
# breaks the mirror convention used elsewhere under test/nixos/ only because
# default.nix is taken here: this directory's default.nix is the check entry
# point.

{ evalConfig, lib, ... }:

with lib;
{
  testUserIsAliasedToUsersUsers = {
    expr =
      let u = (evalConfig []).users.users.test;
      in { inherit (u) home isNormalUser; };
    expected = { home = "/home/test"; isNormalUser = true; };
  };

  # `user` borrows users.users' own element type, so lists merge instead of
  # clobbering. This used to be types.attrs, whose shallow // meant that of the
  # nine modules contributing to user.extraGroups only the last survived when
  # read back off config.user. Both views must agree, and both must hold every
  # contributor.
  testConfigUserAggregatesLists = {
    expr =
      let c = evalConfig [{
            modules.hyprland.enable = true;   # adds "input"
            modules.profiles.hardware = [ "audio" ];  # adds "audio"
          }];
          groups = sort lessThan c.user.extraGroups;
      in {
        agree = groups == sort lessThan c.users.users.test.extraGroups;
        merged = all (g: elem g groups) [ "audio" "input" "wheel" ];
      };
    expected = { agree = true; merged = true; };
  };
}
