# Test Report: Clash Verge NixOS Service Tun

## Summary

PASS. The affected `axiom` NixOS configuration evaluates with declarative Clash Verge service mode, TUN mode, autostart, service command generation, capability bounding set, and TUN firewall allowances.

## Commands

- `nix eval --no-eval-cache .#nixosConfigurations.axiom.options.programs.clash-verge --apply builtins.attrNames`
  - Result: PASS; returned `[ "autoStart" "enable" "package" "serviceMode" "tunMode" ]`.
  - Reason: Confirms the pinned nixpkgs supports the options used by this module and does not support the initially considered `group` option.
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.programs.clash-verge.serviceMode`
  - Result: PASS; returned `true`.
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.programs.clash-verge.tunMode`
  - Result: PASS; returned `true`.
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.programs.clash-verge.autoStart`
  - Result: PASS; returned `true`.
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.networking.firewall.trustedInterfaces`
  - Result: PASS; returned `[ "Mihomo" "Meta" "lo" ]`.
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.networking.firewall.extraReversePathFilterRules`
  - Result: PASS; returned the expected `iifname { "Mihomo", "Meta" } accept` rule.
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.systemd.services.clash-verge.serviceConfig.ExecStart`
  - Result: PASS; returned a `clash-verge-rev-2.4.3/bin/clash-verge-service` store path.
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.systemd.services.clash-verge.serviceConfig.CapabilityBoundingSet`
  - Result: PASS; returned a capability set containing `CAP_NET_ADMIN` and `CAP_NET_RAW`.
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
  - Result: PASS; returned `/nix/store/f4r9vmnq7rjxzc5j0mb6arj577c5zv4q-nixos-system-axiom-25.11.20260203.e576e3c.drv`.

## Non-Blocking Observations

- Nix evaluation prints existing repository warnings about `specialArgs.pkgs`, `mesa.drivers`, `hardware.pulseaudio`, and `system`; these are pre-existing evaluation warnings outside this task's scope.
- A probe for `systemd.services.clash-verge.serviceConfig.AmbientCapabilities` failed because that attribute is not present; the upstream module exposes the needed service privileges through `CapabilityBoundingSet` instead.

## Why These Checks

Targeted `nix eval` checks directly validate the NixOS option values and generated systemd/firewall configuration touched by this task. Evaluating `system.build.toplevel.drvPath` provides full configuration evaluation without requiring a local system switch or build.
