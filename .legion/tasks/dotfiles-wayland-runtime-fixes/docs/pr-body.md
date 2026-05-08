## Summary

- Point greetd/UWSM at the evaluated `hyprland-uwsm.desktop` session instead of the absent `hyprland.desktop` entry.
- Keep NetworkManager as the network owner on `axiom`: iwd no longer manages DHCP/routes, `dhcpcd` is disabled, and `enp14s0` gets a NetworkManager wired DHCP/autoconnect profile.

## Validation

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- Targeted eval for Hyprland session entry and NetworkManager/iwd/resolved/dhcpcd effective state
- `git diff --check`

## Notes

- Runtime login and physical network checks still need to be done on `axiom`; this PR validates the generated NixOS closure and effective configuration.
