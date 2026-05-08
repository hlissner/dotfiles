# Dotfiles Wayland Runtime Follow-up

## Task Contract

Name: Dotfiles Wayland Runtime Follow-up

Task ID: `dotfiles-wayland-runtime-followup`

## Goal

Fix the next set of `axiom` runtime regressions after the Wayland runtime fixes: Hyprland now reports deprecated/invalid rule syntax during startup, and networking still does not come up reliably.

## Problem

The current `origin/master` validates at build/eval time, but deployment still fails at runtime. Hyprland reports `windowrulev2` deprecation plus syntax errors, which can break compositor startup or rule loading. Network startup still appears broken on `axiom`, so the previous NetworkManager/iwd/dhcpcd ownership fix was incomplete.

## Acceptance

- Generated Hyprland config no longer contains deprecated `windowrulev2` directives.
- Hyprland rule syntax is compatible with the evaluated Hyprland package used by `axiom`.
- `axiom` networking has a coherent NetworkManager + iwd + resolved startup path that can create connections for both Wi-Fi and wired interfaces without legacy DHCP ownership.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passes.
- Targeted evals document generated Hyprland rule output and effective network settings.
- Delivery goes through isolated worktree, PR, verification, review, walkthrough, wiki writeback, cleanup, and main refresh.

## Assumptions

- The user-reported `hyperland` refers to Hyprland.
- `axiom` is still the primary affected host.
- The previous `hyprland-uwsm.desktop` fix remains valid and should not be reverted.
- NetworkManager should own DHCP/routes while iwd provides Wi-Fi backend support.

## Constraints

- Work from latest `origin/master` in `.worktrees/dotfiles-wayland-runtime-followup/`.
- Preserve Hyprland + UWSM + DMS/Quickshell + Zen direction.
- Preserve NetworkManager + iwd + resolved direction.
- Do not restore old X11/bspwm/sxhkd/Waybar/Dunst compatibility paths.
- Do not add secrets, imperative host-specific commands, or Darwin desktop behavior.

## Scope

- Hyprland generated rule syntax in the desktop module/theme output.
- `axiom` NetworkManager/iwd/resolved startup ownership and default connection creation.
- Task-local Legion evidence and PR lifecycle documents.

## Non-goals

- No broad desktop redesign.
- No changes to browser, Discord, Steam, Bluetooth, media, theme visuals, or Darwin behavior unless required for evaluation.
- No manual runtime commands or secrets in repo.

## Risks

- Hyprland config syntax changed across versions, and build-time Nix validation does not parse Hyprland config by itself.
- NetworkManager may require default connection behavior for Wi-Fi or wired devices even when declarative profiles exist.
- Without live `axiom` access, validation can prove generated configuration but not physical link/authentication behavior.

## Design Summary

- Inspect the generated Hyprland config and upstream Hyprland rule syntax for the evaluated package version.
- Convert deprecated `windowrulev2` directives to the supported syntax with the smallest config-generation change.
- Re-check NetworkManager/iwd defaults and remove settings that prevent default connection creation unless they are still justified.
- Validate with actual `axiom` build plus targeted evals of generated config and network service ownership.

## Phases

- Materialize the Legion task contract and open the PR worktree.
- Inspect generated Hyprland config and network effective state.
- Implement minimal syntax/network startup fixes.
- Run build/eval verification and record evidence.
- Run readiness review, walkthrough, wiki writeback, PR lifecycle, cleanup, and main refresh.
