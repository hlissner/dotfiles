# Review Change: Clash Verge NixOS Service Tun

## Verdict

PASS.

## Blocking Findings

None.

## Scope Check

- In scope: `modules/desktop/apps/clash-verge.nix` now uses upstream `programs.clash-verge` with `enable`, `package`, `serviceMode`, `tunMode`, and `autoStart`.
- In scope: firewall allowances are limited to `Mihomo` and `Meta` TUN interface names required for this app.
- In scope: task-local Legion evidence was added under `.legion/tasks/clash-verge-nixos-service-tun/`.
- No unrelated host, profile, subscription, or Mihomo WebUI migration changes were introduced.

## Correctness Review

- The previous `user.packages = [ cfg.package ]` path is replaced by upstream `programs.clash-verge`, which is the correct NixOS integration point for service-mode generation.
- `package = cfg.package` preserves the existing module override surface.
- Verification confirms `serviceMode`, `tunMode`, and `autoStart` evaluate to `true` for `axiom`.
- Verification confirms `clash-verge.service` uses the package's `bin/clash-verge-service` command and has a capability bounding set containing `CAP_NET_ADMIN` and `CAP_NET_RAW`.
- Verification confirms firewall trusted interfaces and reverse-path filter rules contain the intended TUN interface allowance.
- Full `axiom` system derivation evaluation succeeds.

## Security Lens

Applied because this change modifies a privileged system service, Linux capabilities, and firewall trust boundaries.

- The capability change is delegated to the upstream NixOS `programs.clash-verge` module rather than hand-rolling service permissions.
- The firewall trust change is scoped to two expected TUN interface names and does not open ports or globally disable reverse-path filtering.
- Residual risk: a malicious or misconfigured process that can create an interface named `Mihomo` or `Meta` may benefit from the trusted-interface policy. This is acceptable for the current task because those names are the expected Clash Verge/Mihomo TUN interfaces and the alternative would leave TUN mode unusable on NixOS.

## Non-Blocking Notes

- The pinned nixpkgs module does not expose `group`; leaving it out is safer than relying on this repo's disabled module option checking to silently ignore an inert setting.
- Runtime connectivity still depends on Clash Verge profile/core configuration, which is outside this task's scope.
