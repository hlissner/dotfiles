# Clash Verge NixOS Service Tun

## Metadata

- `task-id`: `clash-verge-nixos-service-tun`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

The dotfiles Clash Verge app module now uses the upstream NixOS `programs.clash-verge` module instead of only installing `pkgs.clash-verge-rev` as a user package. Hosts that enable `modules.desktop.apps.clash-verge.enable` get declarative service mode, TUN mode, autostart, and the configured package pass-through.

The module also trusts common Mihomo/Clash Verge TUN interface names, `Mihomo` and `Meta`, and adds a reverse-path filter exception for those interfaces so NixOS firewall policy does not drop TUN traffic by default.

## Reusable Decisions

- On NixOS, do not use Clash Verge Rev's GUI service/TUN installers. Keep service generation and capabilities in `programs.clash-verge`.
- The pinned nixpkgs Clash Verge module exposes `autoStart`, `enable`, `package`, `serviceMode`, and `tunMode`; it does not expose `group`.
- If Clash Verge TUN mode starts but has no connectivity, first confirm the live TUN interface name and firewall/rpfilter behavior before changing proxy profile logic.

## Validation

Local validation passed for exposed option names, `serviceMode = true`, `tunMode = true`, `autoStart = true`, generated `clash-verge-service` systemd command, capability bounding set including `CAP_NET_ADMIN` and `CAP_NET_RAW`, TUN firewall rules, and full `axiom` system drv evaluation.

## Related Raw Sources

- `plan`: `.legion/tasks/clash-verge-nixos-service-tun/plan.md`
- `log`: `.legion/tasks/clash-verge-nixos-service-tun/log.md`
- `tasks`: `.legion/tasks/clash-verge-nixos-service-tun/tasks.md`
- `test-report`: `.legion/tasks/clash-verge-nixos-service-tun/docs/test-report.md`
- `review`: `.legion/tasks/clash-verge-nixos-service-tun/docs/review-change.md`
- `walkthrough`: `.legion/tasks/clash-verge-nixos-service-tun/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/clash-verge-nixos-service-tun/docs/pr-body.md`

## Notes

- Runtime deployment still needs a normal host rebuild/switch.
- Runtime profile and subscription contents remain outside this task.
