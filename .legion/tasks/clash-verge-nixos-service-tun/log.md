# Log: Clash Verge NixOS Service Tun

## 2026-05-10

- Created task contract from user request to make Clash Verge Rev use NixOS declarative service/TUN mode instead of the GUI installer path.
- Scope is limited to the existing `modules.desktop.apps.clash-verge` module and required firewall allowance for common TUN interface names.
- During validation, confirmed pinned nixpkgs exposes `autoStart`, `enable`, `package`, `serviceMode`, and `tunMode`, but not `group`; removed the inert `group` assignment from implementation and contract summary.
- Implemented `programs.clash-verge` service/TUN/autostart wiring and TUN firewall allowances in the worktree.
- Verification passed for option values, generated service command, capability bounding set, firewall rules, and `axiom` system drv evaluation. See `docs/test-report.md`.
- Review passed with security lens applied to service capabilities and firewall trust-boundary changes. See `docs/review-change.md`.
- Produced implementation-mode walkthrough and PR body from existing verification/review evidence.
- Completed Legion wiki writeback with task summary, current decision, and validation pattern.
