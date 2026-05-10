# Review Change: axiom-caelestia-shell-migration

Date: 2026-05-10

## Decision

PASS.

No blocking correctness, maintainability, scope, or security/privacy findings were found in the implementation diff.

## Evidence Reviewed

- Task contract: `.legion/tasks/axiom-caelestia-shell-migration/plan.md`
- Approved design: `.legion/tasks/axiom-caelestia-shell-migration/docs/rfc.md`
- Verification evidence: `.legion/tasks/axiom-caelestia-shell-migration/docs/test-report.md`
- Worktree diff, including the Caelestia flake input, `modules/desktop/caelestia.nix`, Hyprland integration changes, active end4 source removals, and README update.
- Additional spot checks during review:
  - `git diff --check` passed.
  - Caelestia service ExecStart evaluates to `/nix/store/...-caelestia-shell-1.0.0/bin/caelestia-shell`.
  - Generated `caelestia/shell.json` evaluates to minimal Nix-owned defaults with `launcher.enableDangerousActions = false`.
  - Active source scans over `config/` and `modules/` found no legacy end4/quickshell `ii` references for the targeted patterns.

## Blocking Findings

None.

## Correctness and Scope Review

- The active shell service is now `systemd.user.services.caelestia-shell` and starts the upstream CLI-enabled Caelestia package, satisfying the primary migration goal.
- `flake.nix` and `flake.lock` add `github:caelestia-dots/shell` with `nixpkgs-unstable` following, matching the RFC's upstream Nix package path.
- The local module boundary is preserved: the implementation does not import Caelestia's Home Manager module as the primary owner, and it writes repository-owned XDG config through this repo's Nix abstraction.
- Hyprland remains repo/Nix-owned: checked-in `hyprland.conf` is a small local source root, while generated `custom/*.conf`, `monitors.conf`, and `workspaces.conf` retain host policy and keybind ownership.
- Active end4 product source paths are removed from the worktree and no active `config/` or `modules/` references remain for `quickshell --config ii`, `IllogicalImpulse`, `qsConfig`, end4 IPC names, matugen, or fuzzel.
- Darwin isolation is maintained by the Caelestia module assertion and Linux-only package defaults; the Axiom toplevel build evidence passed in `test-report.md`.

## Maintainability Review

- The new Caelestia module is small, option-driven, and keeps package/config/service responsibilities localized.
- Generated Caelestia settings are intentionally minimal rather than copying upstream defaults, reducing future drift.
- Deleting the end4-specific Quickshell module and vendored runtime tree reduces ambiguity and avoids maintaining two shell products.

## Security / Privacy Lens

Applied because the change introduces a third-party desktop shell/CLI with screenshot, recording, clipboard, and launcher/global-shortcut entrypoints.

No exploitable local trust-boundary issue was found:

- The third-party code is pinned through `flake.lock` rather than fetched or cloned mutably at runtime.
- No secrets, tokens, webhook/auth logic, signing keys, or credential files are added.
- Dangerous launcher actions are explicitly disabled in generated config.
- Clipboard/screenshot/record commands are user-session desktop functions exposed via local keybinds; they do not add network exfiltration or privilege escalation in this repository's integration layer.

## Residual Risks / Follow-ups

- Live graphical behavior remains unexercised in automation because no Hyprland Wayland session was available; post-deployment smoke should cover panel rendering, global shortcuts, screenshot/record/clipboard flows, lock/session UI, tray, and OSD behavior.
- Hyprland config syntax was covered indirectly by Nix evaluation/build; a live or assembled-config `Hyprland --verify-config` remains a useful follow-up.
- The Legion wiki current-truth update is still a later closeout step; complete it before PR lifecycle closure so future work no longer treats end4 as current product truth.
