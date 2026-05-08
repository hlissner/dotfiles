# Dotfiles Quickshell Product Desktop

## Goal

Rework the Linux workstation desktop into an Isabel-first Hyprland + Quickshell product desktop. The target is not a hlissner-style keyboard-driven workstation with a launcher bolted on; it is a visible, elegant, GUI-first desktop surface that is at least as complete as Isabel's reference experience and can be refined later by preference.

## Problem

The previous Wayland product overhaul cleaned up much of the old desktop architecture and adopted Hyprland + UWSM + DMS/Quickshell, but the runtime experience still feels like the wrong product. Axiom currently boots into the autumnal wallpaper plus Rofi/shortcut-oriented interaction model. That satisfies part of the hlissner cleanup goal, but fails the actual user-facing goal: a polished desktop with a persistent shell, discoverable controls, and an onboarding path that does not assume the user already knows a shortcut-heavy tiling workflow.

## Acceptance

- Axiom's default desktop visibly uses a Quickshell-based product shell with a persistent bar/dock/status surface inspired by Isabel's screenshots and configuration direction.
- Rofi is not the primary visible desktop shell or required control center. It may be removed or kept only as a non-primary fallback if a concrete need remains.
- Hyprland defaults move toward Isabel's product feel: rounded corners, gaps, polished blur/shadow, declarative monitor/workspace behavior, common app bindings, and GUI-friendly window rules.
- GUI entry points exist for launching apps, opening files, power actions, audio, Wi-Fi, Bluetooth, notifications, screenshot/recording, and a shortcut/onboarding guide.
- A user-facing desktop guide documents the visible UI, GUI entry points, and gradual shortcut learning path.
- Legacy desktop residue inconsistent with the new direction is removed rather than kept for compatibility.
- `nix build` for the target Axiom NixOS system succeeds before delivery.

## Assumptions

- The reference Isabel experience is a product baseline, not a literal requirement to import her `garden` module framework.
- The current Isabel snapshot exposes Quickshell enablement and Hyprland product behavior, while the visible screenshot is the strongest guide for the desired shell shape.
- Axiom is the primary runtime target for this task.
- Backward compatibility with the hlissner desktop experience, Rofi-first workflow, or old X11/bspwm paths is not required.

## Constraints

- Keep repository architecture Nix-native and compatible with existing host/module layout unless a concrete product reason requires changing it.
- Keep Darwin isolated from Linux desktop imports.
- Do not copy large upstream frameworks wholesale when a smaller local shell can satisfy the product goal.
- Persist implementation work in the PR worktree and deliver through the Legion worktree/PR lifecycle.
- Build validation must include an actual `nix build` for Axiom, not only evaluation or dry-run.

## Scope

- Axiom Hyprland defaults, shell startup, Quickshell package/config wiring, desktop theme/polish, and user-facing desktop documentation.
- Replacement or demotion of Rofi and DMS desktop-shell behavior where they conflict with the Isabel-first product target.
- Cleanup of active or stale desktop configuration that contradicts the new direction.
- Verification evidence for build, generated Hyprland config, Quickshell config presence, desktop entry points, and regression searches.

## Non-Goals

- No Secure Boot or Windows dual-boot implementation in this task.
- No full import of Isabel's `garden` framework.
- No attempt to preserve hlissner's desktop UX if it conflicts with the product target.
- No broad application expansion beyond what is needed to make the desktop shell and core GUI entry points usable.
- No Darwin desktop feature work.

## Design Summary

- Treat Isabel as the desktop product baseline and hlissner only as optional low-level Nix maintenance inspiration.
- Build a local Quickshell product shell instead of relying on DMS as an opaque shell or Rofi as the visible interaction layer.
- Use a persistent vertical or macOS-like shell surface with app launchers, workspace/status indicators, clock, network/audio/bluetooth/power controls, and discoverable help.
- Keep Hyprland tiling available but make the first experience usable through visible GUI controls and documentation.
- Remove stale desktop payloads and active defaults that imply the old Rofi/shortcut-first product.

## Risks

- Quickshell/QML integration can fail at build or runtime if package APIs differ from assumptions.
- A minimal local shell may not equal every feature in Isabel's private runtime environment on the first pass.
- Visual polish is subjective; the target is to meet the documented Isabel-like baseline first, then let the user refine taste.
- Full `nix build` can expose unrelated repository build blockers; in-scope blockers must be fixed, unrelated blockers must be documented clearly.

## Phases

- RFC: specify the Quickshell product surface, Hyprland deltas, removed legacy paths, docs, and validation plan.
- Implementation: add the shell, wire it into Axiom, demote/remove Rofi/DMS where needed, and add documentation.
- Verification: run `nix build` for Axiom plus targeted config checks and searches.
- Review and delivery: readiness review, walkthrough, wiki writeback, commit, PR, checks/review follow-up, cleanup, and main refresh.
