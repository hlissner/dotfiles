# RFC: Isabel-first Quickshell Product Desktop

> **Profile**: RFC Heavy (high-risk desktop product rewrite)  
> **Status**: Draft  
> **Owners**: agent/user  
> **Created**: 2026-05-08  
> **Last Updated**: 2026-05-08

## Executive Summary

- **Problem**: The current Axiom desktop is technically Hyprland + Quickshell-capable but feels like the wrong product: autumnal wallpaper, Rofi/shortcut-first interaction, and no visible Isabel-like desktop shell.
- **Decision**: Replace the DMS/Rofi-first desktop surface with a local Quickshell product shell and Isabel-like Hyprland defaults. hlissner remains useful for low-level cleanup only, not for desktop UX.
- **Why now**: The user explicitly rejected the current desktop experience and allowed discarding hlissner desktop configs, including Rofi, without backward compatibility constraints.
- **Impact**: Axiom becomes the primary polished Hyprland + Quickshell target with visible GUI controls, desktop documentation, and a gentler shortcut learning path.
- **Risks**: Quickshell/QML API mismatch, runtime visual differences from Isabel, accidental loss of launch/control entry points, and build failures.
- **Rollout**: Implement in one PR worktree, validate with Axiom `nix build`, targeted config checks, and regression searches.
- **Rollback**: Revert the PR or disable the local Quickshell product shell and restore the previous DMS/Rofi-enabled generation.

## 1. Background / Motivation

Previous work correctly removed old active X11/bspwm-style desktop paths and adopted Hyprland + UWSM. However, the visible product is still not aligned with the user's desired daily desktop. The requested direction is Isabel-like: a persistent visible shell, polished visual defaults, GUI operation paths, and documentation for gradual shortcut learning.

This task treats that user-facing product goal as the source of truth. A clean module graph is not enough if the resulting desktop still feels like a keyboard-centric tiling setup.

## 2. Goals

- Make Axiom boot into a visible Quickshell product shell by default.
- Match Isabel's product feel at minimum: persistent side shell/dock/status surface, rounded/gapped Hyprland, common GUI app bindings, and polished window rules.
- Remove or demote Rofi and DMS where they conflict with the new Quickshell shell owner.
- Provide GUI entry points for daily desktop tasks.
- Add user-facing documentation for visible controls and shortcut onboarding.
- Pass actual `nix build` for Axiom.

## 3. Non-goals

- No full import of Isabel's `garden` framework.
- No preservation of hlissner desktop UX or Rofi-first workflows for compatibility.
- No Secure Boot, dual boot, or Darwin desktop implementation.
- No broad GUI application suite expansion except where needed for core shell entry points.

## 4. Constraints

- Linux desktop imports must stay out of Darwin.
- The shell must be local and reviewable in this repository.
- Keep Quickshell simple enough to build against packaged Quickshell without relying on hidden Isabel code.
- Axiom is the required build target.
- Work happens in `.worktrees/dotfiles-quickshell-product-desktop/` and ships through a PR.

## 5. Definitions

- **Product shell**: the visible desktop layer that provides persistent status, launch, controls, and help. For this task it is local Quickshell QML.
- **Fallback launcher**: an optional non-primary command launcher. Rofi can only remain in this role if it does not define the visible desktop experience.
- **Isabel-like**: at least the visible qualities from Isabel's screenshot and Hyprland config direction: side shell, rounded/gapped windows, direct GUI app bindings, polished floating rules, and status/control affordances.

## 6. Proposed Design

### 6.1 High-level Architecture

- Replace `modules/desktop/quickshell.nix` from `dms run` service ownership to a local Quickshell service running repository-owned QML.
- Add `config/quickshell/` with a compact shell:
  - left vertical panel/dock inspired by Isabel's screenshot;
  - pinned app launchers for browser, terminal, files, Discord, Steam, docs/help;
  - workspace indicators for 1-9;
  - clock/status area;
  - visible buttons for notifications/help, audio, network, Bluetooth, screenshot, and power;
  - simple popups/actions backed by safe commands where full native service integration is not yet necessary.
- Update Hyprland defaults toward Isabel's product feel:
  - nonzero gaps and rounded corners;
  - blur/shadow tuned for polish;
  - GUI app keybindings for browser, files, terminal, launcher/help, lock, screenshot;
  - window rules for network/Bluetooth/audio dialogs, file pickers, sharing indicators, Discord, Steam, picture-in-picture;
  - keep UWSM/greetd and existing visible-session bootstrap.
- Update Axiom defaults:
  - enable Quickshell product shell;
  - stop enabling Rofi as an Axiom desktop app unless retained only as fallback;
  - include file manager and GUI control dependencies needed by the shell.
- Add `docs/axiom-desktop.md` as the onboarding guide.
- Remove stale desktop payloads that contradict the new direction, including unreferenced `config/ncmpcpp/`.

### 6.2 Quickshell Surface

The first-pass shell should be deliberately product-shaped, not a technical demo:

- A left-side translucent rounded dock occupying the screen height, matching the Isabel screenshot's visual grammar.
- Top identity/logo button and workspace buttons.
- Middle pinned launchers: Zen, terminal, files, Discord/Vesktop, Steam, help.
- Bottom controls: Wi-Fi/network editor, Bluetooth manager, audio mixer, notifications/help, screenshot, lock/power.
- Click actions should launch existing GUI tools or direct commands; command execution is acceptable for first pass if documented and buildable.

### 6.3 Hyprland Surface

Hyprland remains the compositor, but it should not be the whole product. Defaults should prefer user-visible polish over extreme keyboard efficiency:

- Use `gaps_in = 8`, `gaps_out = 8`, `border_size = 2`, rounded corners around `12-15`, and blur/shadow similar to Isabel.
- Set `$mod`/`$prefix` bindings for discoverable direct actions: browser, files, terminal, docs/help, lock, screenshot, workspace navigation.
- Keep mouse drag/resize and media keys.
- Reduce shortcut-only modal dependence where a visible Quickshell control exists.
- Keep generated monitor/workspace support from the existing module and improve defaults for primary monitor assignment.

### 6.4 Rofi and DMS Handling

- DMS should not own the default shell surface for Axiom after this change.
- Rofi should not be enabled by default on Axiom. Existing Rofi module can remain in the repository if other hosts still enable it, but the Axiom desktop should not depend on it for primary operation.
- Any keybindings that currently call `hey @rofi ...` must be replaced for the Axiom/Hyprland path with Quickshell help, direct app commands, or GUI tools.

## 7. Alternatives Considered

### Option A: Keep DMS and polish around it

- Pros: Smallest code change; continues prior task direction.
- Cons: User already rejected the visible result; DMS is opaque here and does not give us a local Isabel-like shell to shape.
- Why not: It optimizes for hlissner continuity instead of the user-facing product target.

### Option B: Import Isabel's framework or QML wholesale

- Pros: Theoretically closest to Isabel if all source exists and ports cleanly.
- Cons: Her inspected snapshot does not expose a reusable shell QML tree; `garden` import would be a large framework migration with high coupling.
- Why not: Too much architecture churn and not enough reusable code evidence.

### Option C: Build a local Quickshell product shell

- Pros: Directly targets the requested UX, stays reviewable, avoids `garden`, and can replace Rofi/DMS incrementally within this repo.
- Cons: First pass may not match every private Isabel runtime behavior and needs careful build/runtime validation.
- Decision: Choose Option C.

## 8. Migration / Rollout / Rollback

### Migration Plan

- No user data migration.
- Add local Quickshell config and service wiring.
- Update Axiom module defaults to use the new shell and stop default Rofi dependence.
- Remove stale config payloads that are unreferenced and contrary to the product direction.
- Update documentation and verification evidence.

### Rollout Plan

- Land as one PR targeting `origin/master`.
- Required acceptance before PR: Axiom `nix build` passes.
- Runtime deploy remains a separate manual step after merge, but the generated config and service wiring must be inspectable.

### Rollback Plan

- Before merge: revert the PR branch commit(s).
- After merge: revert the PR or boot/switch to the previous NixOS generation.
- If only Quickshell runtime fails after build: temporarily disable `modules.desktop.quickshell.enable` or restore the previous generation while preserving the rest of the system.

## 9. Observability

- Quickshell runs as a systemd user service with restart behavior and journal logs.
- Hyprland remains verifiable with `Hyprland --verify-config` against the generated full config.
- Documentation should include basic troubleshooting commands for the shell service and Hyprland config validation.

## 10. Security & Privacy

- No new secrets or network-facing services.
- Shell buttons execute local desktop commands only.
- Power/lock buttons must use existing system commands and should not weaken lock behavior.
- Do not introduce remote fetches or mutable runtime code for the shell.

## 11. Testing Strategy

- Required build: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Targeted eval: verify Axiom enables Quickshell, does not enable Rofi by default, has the Quickshell config linked, and has expected Hyprland service/session wiring.
- Hyprland parser: build combined generated/base/theme config and run evaluated `Hyprland --verify-config`.
- Regression search: active desktop config should not rely on `hey @rofi` for primary Hyprland operation, and stale `config/ncmpcpp/` should be removed if unreferenced.
- Docs check: `docs/axiom-desktop.md` exists and covers visible UI, GUI operations, shortcuts, and troubleshooting.

## 12. Milestones

- Milestone 1: Local Quickshell shell and module ownership
  - Scope: `modules/desktop/quickshell.nix`, `config/quickshell/**`, Axiom host defaults.
  - Acceptance: Axiom uses local Quickshell service/config and no longer depends on Rofi/DMS as product shell.
  - Rollback impact: Disable new Quickshell module or revert PR.
- Milestone 2: Isabel-like Hyprland defaults and GUI entry points
  - Scope: `modules/desktop/hyprland.nix`, `config/hypr/hyprland.conf`, theme Hyprland defaults, app/file manager dependencies.
  - Acceptance: rounded/gapped polished defaults, GUI-friendly bindings/rules, no primary `hey @rofi` path.
  - Rollback impact: Restore previous Hyprland config generation.
- Milestone 3: Documentation, cleanup, and build validation
  - Scope: `docs/axiom-desktop.md`, stale desktop config removal, Legion evidence.
  - Acceptance: `nix build` for Axiom passes and docs describe GUI operations and shortcut onboarding.
  - Rollback impact: Docs/cleanup are safe to revert with PR.

## 13. Open Questions

- [ ] Exact visual preference after first Isabel-aligned pass is intentionally deferred to user refinement.
- [ ] Live Quickshell rendering must be confirmed on Axiom after build/deploy.

## 14. Implementation Notes

- Prefer small local QML files over a complex framework.
- Prefer direct GUI commands for first-pass buttons: Zen, foot, Thunar/Cosmic Files, Vesktop, Steam, Blueman, nm-connection-editor, pavucontrol/wpctl, screenshot command, lock/power.
- Keep Quickshell action commands declarative enough to review and document.
- Do not delete the Rofi module globally if other hosts still enable it; remove it from Axiom and from primary Hyprland keybindings.

## 15. References

- Plan: `.legion/tasks/dotfiles-quickshell-product-desktop/plan.md`
- Research: `.legion/tasks/dotfiles-quickshell-product-desktop/docs/research.md`
- Isabel reference: `/tmp/opencode/isabelroses-dotfiles`, commit `b9c5f08`
- hlissner reference: `/tmp/opencode/hlissner-dotfiles`, commit `1b4383a`
- Prior product task: `.legion/tasks/dotfiles-wayland-product-overhaul/`
