# Clash Verge NixOS Service Tun

## Goal
Make Clash Verge Rev work the NixOS way in this dotfiles repo: the system module should install the app, create the service-mode backend, grant TUN capabilities, and allow the TUN interface through the firewall. The GUI should remain only a graphical controller.

## Problem
The current `modules.desktop.apps.clash-verge` module only adds `pkgs.clash-verge-rev` to the user package set. On NixOS, using Clash Verge Rev's GUI buttons to install service mode or TUN mode is brittle because generic Linux installers expect to write scripts, capabilities, and systemd units at runtime, while `/nix/store` is immutable.

## Acceptance
- Hosts enabling `modules.desktop.apps.clash-verge.enable` get `programs.clash-verge.enable = true` with `serviceMode = true` and `tunMode = true`.
- The module keeps `package` configurable and uses it for the upstream `programs.clash-verge.package` option.
- Firewall rules trust common Mihomo/Clash Verge TUN interface names so TUN traffic is not dropped by NixOS firewall or reverse-path filtering.
- Existing enabled host behavior is preserved aside from making Clash Verge service/TUN declarative.
- Local Nix evaluation succeeds, or any blocker is documented with evidence.
- Changes are delivered through the Legion worktree/PR workflow.

## Scope
- Update `modules/desktop/apps/clash-verge.nix`.
- Keep the change host-agnostic so it applies to `axiom` and any future host enabling the same module.
- Add task-local verification, review, walkthrough, and wiki evidence.

## Non-goals
- Do not switch to `services.mihomo` plus WebUI in this task.
- Do not manage Clash Verge profiles, subscriptions, or runtime YAML config.
- Do not repair or use Clash Verge's GUI installer flow.
- Do not change unrelated firewall policy beyond the TUN interface allowance required for this app.

## Assumptions
- The pinned nixpkgs exposes `programs.clash-verge.serviceMode` and `programs.clash-verge.tunMode`.
- Common Clash Verge/Mihomo TUN interfaces are named `Mihomo` or `Meta`.
- The pinned nixpkgs Clash Verge module does not expose a `group` option; service permissions stay with the upstream module defaults.

## Constraints
- Follow Legion workflow and the `git-worktree-pr` envelope for repository modifications.
- Preserve unrelated dirty work in the main checkout.
- Keep the implementation minimal and aligned with existing dotfiles module style.

## Risks
- If the pinned nixpkgs lacks `tunMode`, evaluation will fail and the module may need a compatibility adjustment or nixpkgs bump.
- TUN runtime behavior still depends on Clash Verge profile/core config, which is outside this task.
- Interface names can vary; allowing both common names is intentionally slightly broader than a single-interface rule.

## Design Summary
Replace the module's direct `user.packages` installation path with the upstream NixOS `programs.clash-verge` module. Enable service mode, TUN mode, and autostart declaratively, and pass through the configured package. Add targeted firewall trust and reverse-path filter acceptance for `Mihomo` and `Meta` interfaces so generated TUN traffic is allowed by NixOS networking policy.

## Phases
1. Materialize Legion task contract.
2. Implement the Clash Verge module change in an isolated worktree.
3. Evaluate the affected host configuration.
4. Review change scope and safety.
5. Produce walkthrough/wiki evidence and complete PR lifecycle.
