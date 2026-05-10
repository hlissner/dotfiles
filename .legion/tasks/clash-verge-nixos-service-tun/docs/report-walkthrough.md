# Report Walkthrough: Clash Verge NixOS Service Tun

Mode: implementation.

## What Changed

- `modules.desktop.apps.clash-verge` now delegates installation and backend service generation to upstream `programs.clash-verge`.
- Service mode, TUN mode, and autostart are enabled declaratively for hosts that set `modules.desktop.apps.clash-verge.enable = true`.
- The configured `package` option is still passed through, preserving the existing override surface.
- NixOS firewall policy now trusts the common Clash Verge/Mihomo TUN interfaces `Mihomo` and `Meta`, with a matching reverse-path filter exception.

## Why

Clash Verge Rev's GUI installer path is not a good fit for NixOS because it expects runtime mutation of service files, permissions, and installer scripts. Using the NixOS module keeps service creation and capabilities in the declarative system configuration, while the GUI remains only the controller.

## Evidence

- `docs/test-report.md`: confirms the pinned nixpkgs exposes the used options, `serviceMode = true`, `tunMode = true`, `autoStart = true`, expected firewall rules, generated `clash-verge-service` command, required capability bounding set, and successful `axiom` drv evaluation.
- `docs/review-change.md`: PASS with security lens applied to privileged service capabilities and firewall trust-boundary changes.

## Reviewer Notes

- The pasted `group = "users"` idea was not kept because the pinned nixpkgs `programs.clash-verge` module does not expose a `group` option.
- Runtime profile/subscription configuration remains outside this task. If TUN still has no connectivity after rebuild, the next check should be Clash Verge/Mihomo runtime config and actual TUN interface naming on the machine.

## Expected Operator Flow

After merge and local sync, rebuild the target host with the normal NixOS flow. Do not use Clash Verge Rev's GUI buttons for service-mode or TUN installation.

Useful runtime checks after switching:

- `systemctl status clash-verge.service`
- `journalctl -u clash-verge.service -b --no-pager`
- `ip link | grep -Ei 'mihomo|meta|tun'`
