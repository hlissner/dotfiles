# Dotfiles Wayland Runtime Fixes

## Task Contract

Name: Dotfiles Wayland Runtime Fixes

Task ID: `dotfiles-wayland-runtime-fixes`

## Goal

Restore `axiom` runtime viability after the Wayland product overhaul by fixing the Hyprland/UWSM login session entry and workstation network startup path.

## Problem

The latest `origin/master` builds after the portal unit fix, but runtime deployment on `axiom` reports a missing Hyprland desktop entry and no working network. These are activation/runtime regressions, not a request to redesign the Wayland stack.

## Acceptance

- `axiom` has a greetd/UWSM session command that targets an actual desktop session entry provided by the evaluated system closure.
- `axiom` keeps the intended NetworkManager + iwd + resolved Wi-Fi model without conflicting ownership of network configuration.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passes.
- Targeted Nix evaluations document the effective Hyprland session command and network service settings.
- Delivery goes through an isolated worktree, PR, verification evidence, review evidence, walkthrough, wiki writeback, cleanup, and main-workspace refresh.

## Assumptions

- The user-reported `hyperland.desktop` symptom refers to the Hyprland desktop session entry used by greetd/UWSM, even if the exact log spelling differs.
- `axiom` is the primary host for this runtime fix.
- NetworkManager should own IP configuration while using the iwd backend for Wi-Fi scanning and association.

## Constraints

- Work from latest `origin/master` in `.worktrees/dotfiles-wayland-runtime-fixes/`.
- Preserve the Wayland-first product direction: Hyprland + UWSM + DMS/Quickshell + Zen.
- Preserve Wi-Fi direction: NetworkManager + iwd + resolved.
- Do not restore old X11/bspwm/sxhkd/Waybar/Dunst compatibility paths.
- Keep Darwin changes limited to boundary safety only; no Darwin desktop implementation.

## Scope

- Hyprland/UWSM session entry and greetd command wiring.
- `axiom` workstation network ownership/startup settings.
- Task-local Legion evidence and PR lifecycle documents.

## Non-goals

- No broad Wayland redesign.
- No changes to browser, Discord, Steam, Bluetooth, media, theme, or Darwin feature behavior unless needed to preserve evaluation.
- No hardware-specific imperative network commands or secrets.

## Risks

- The NixOS Hyprland module may expose different desktop entry names depending on UWSM integration, package version, or wrapper behavior.
- Misconfiguring iwd networking can leave NetworkManager unable to manage addresses and routes.
- Build-time success may not prove login/network runtime behavior; targeted closure/eval checks are required.

## Design Summary

- Evaluate the actual desktop session entries and greetd command before changing names.
- Use the smallest central Hyprland module adjustment that points greetd/UWSM at the real session entry.
- Ensure iwd does not independently own network configuration when NetworkManager uses the iwd backend.
- Validate with an actual `axiom` toplevel build plus targeted option/closure checks.

## Phases

- Materialize the Legion task contract and open the PR worktree.
- Inspect effective Hyprland session and `axiom` network configuration.
- Implement minimal module fixes.
- Run build/eval verification and record evidence.
- Run readiness review, walkthrough, wiki writeback, PR lifecycle, cleanup, and main refresh.
