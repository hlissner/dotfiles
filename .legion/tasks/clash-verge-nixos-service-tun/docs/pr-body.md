## Summary

- Switch the dotfiles Clash Verge app module to upstream `programs.clash-verge` service/TUN mode instead of only installing the GUI package.
- Add NixOS firewall trust and reverse-path filter allowance for common `Mihomo`/`Meta` TUN interfaces.
- Record Legion verification and review evidence for the `axiom` config.

## Validation

- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.programs.clash-verge.serviceMode` -> `true`
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.programs.clash-verge.tunMode` -> `true`
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.systemd.services.clash-verge.serviceConfig.ExecStart` -> `clash-verge-service`
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.systemd.services.clash-verge.serviceConfig.CapabilityBoundingSet` includes `CAP_NET_ADMIN` and `CAP_NET_RAW`
- `nix eval --no-eval-cache .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` passed

## Legion Evidence

- Plan: `.legion/tasks/clash-verge-nixos-service-tun/plan.md`
- Test report: `.legion/tasks/clash-verge-nixos-service-tun/docs/test-report.md`
- Review: `.legion/tasks/clash-verge-nixos-service-tun/docs/review-change.md`
- Walkthrough: `.legion/tasks/clash-verge-nixos-service-tun/docs/report-walkthrough.md`
