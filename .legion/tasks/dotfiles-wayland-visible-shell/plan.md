# Dotfiles Wayland Visible Shell

## Task Contract

Name: Dotfiles Wayland Visible Shell

Task ID: `dotfiles-wayland-visible-shell`

## Goal

Restore the visible Wayland product surface on `axiom`: after Hyprland starts and the cursor is visible, the session must also start the intended shell layer, wallpaper/background, and user-session bootstrap that make the desktop usable.

## Problem

The latest runtime fixes got networking working and Hyprland starts far enough to show a cursor, but the desktop is otherwise black. This indicates the compositor is alive while the product layer is missing, blocked, or not attached to the active user session. The goal is not to bring back legacy panels; it is to make the Hyprland + UWSM + DMS/Quickshell stack behave like a real product while retaining hlissner-style modular boundaries.

## Acceptance

- `axiom` Hyprland generated config starts the session bootstrap in a way that reaches visible shell/background services.
- DMS/Quickshell and wallpaper/background startup are connected to the correct Hyprland/UWSM user session target or exec path.
- The session no longer depends on an immediate lock-screen pseudo-login path that can mask a broken/empty shell.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passes.
- Targeted evaluations document the effective Hyprland startup commands, user targets/services, and generated shell/wallpaper config.
- Delivery uses isolated worktree, PR, verification evidence, review evidence, walkthrough, wiki writeback, cleanup, and main refresh.

## Assumptions

- The visible cursor means Hyprland starts; the remaining black screen is a session bootstrap/product-surface issue.
- `axiom` is the primary affected host.
- The intended product surface remains DMS/Quickshell, not Waybar/Dunst/Polybar.
- The desired architecture is a hlissner-style split: compositor, shell, theme, and services stay modular, while the product behavior is Isabel-like and usable by default.

## Constraints

- Work from latest `origin/master` in `.worktrees/dotfiles-wayland-visible-shell/`.
- Preserve Hyprland + UWSM + DMS/Quickshell + Zen direction.
- Do not restore old X11/bspwm/sxhkd/Waybar/Dunst compatibility paths.
- Do not add secrets, imperative host-specific hacks, or Darwin desktop behavior.
- Keep the fix minimal and central; avoid spreading ad-hoc startup commands across unrelated modules.

## Scope

- Hyprland session bootstrap commands and user-session target wiring.
- DMS/Quickshell user service attachment and startup ordering.
- Wallpaper/background startup path and generated config required for a non-empty desktop.
- Task-local Legion evidence and PR lifecycle documents.

## Non-goals

- No broad redesign of the Wayland product stack.
- No old desktop stack restoration.
- No unrelated browser, Steam, Discord, Bluetooth, network, or Darwin changes.
- No manual live-machine commands committed to the repo.

## Risks

- Build/eval can prove generated units and config, but not whether Quickshell renders correctly on the physical display.
- UWSM may already manage graphical-session targets, so duplicating target startup could create races or hide failures.
- A lock screen launched too early can look like a black shell if theme/background/shell services do not start.

## Design Summary

- Inspect effective Hyprland `exec-once`, startup hook, user target, DMS/Quickshell service, and wallpaper config.
- Make the compositor bootstrap product services explicitly and predictably through the existing modular interfaces.
- Prefer service/target wiring over scattered imperative commands where possible.
- Validate with actual `axiom` build plus targeted evals for generated config and service attachment.

## Phases

- Materialize the Legion task contract and open the PR worktree.
- Inspect generated session bootstrap and shell service wiring.
- Implement minimal visible-shell startup fix.
- Run build/eval verification and record evidence.
- Run readiness review, walkthrough, wiki writeback, PR lifecycle, cleanup, and main refresh.
