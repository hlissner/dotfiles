# Axiom Caelestia Wallpaper And Launcher Fix

## Contract

- `name`: Axiom Caelestia Wallpaper And Launcher Fix
- `taskId`: `axiom-caelestia-wallpaper-launcher-fix`

## Goal

Make the live Axiom Hyprland session use Caelestia as the wallpaper owner and restore reliable Caelestia launcher app execution after the `caelestia-dots/shell` migration.

## Problem

The current boot shows layered wallpaper behavior and launcher no-op behavior. Logs show multiple overlapping causes: Hyprland still starts a repository-owned `swaybg` wallpaper, Caelestia also creates its own background wallpaper layer, `caelestia-shell.service` runs with a minimal systemd PATH that excludes runtime tools such as `app2unit` and `lsblk`, and an unmanaged duplicate `quickshell` instance is active alongside the systemd-managed service. Caelestia also crashes on logind lock events, causing service restarts and repeated shell layer churn.

## Acceptance

- Caelestia is the only intended wallpaper owner for Axiom's Caelestia desktop session.
- The generated Caelestia state/config seeds `/home/c1/the-great-sage.jpg` as the initial wallpaper without requiring a manual launcher selection after boot.
- Hyprland no longer starts `swaybg` when Caelestia owns wallpaper.
- `caelestia-shell.service` has a runtime PATH sufficient for launcher execution and Caelestia helper commands, including `app2unit`, `lsblk`, and the Caelestia CLI.
- Shell restart/stop keybinds stay inside systemd ownership and do not spawn unmanaged duplicate `quickshell` instances.
- Lock behavior avoids the observed Caelestia logind lock crash path while keeping an explicit lock command available.
- Static validation covers generated Nix shapes for Axiom and the relevant rendered Hyprland/Caelestia config snippets.

## Assumptions

- Axiom should keep `/home/c1/the-great-sage.jpg` as the default wallpaper, but Caelestia should manage and display it.
- Caelestia's wallpaper layer is preferred over the old `swaybg` hook for this host.
- The current `caelestia-shell` upstream package should remain the shell implementation; this task should not vendor or patch upstream QML unless necessary.
- Live session cleanup may require killing the currently unmanaged stray quickshell instance after deployment, but the repository fix should prevent recurrence.

## Constraints

- Keep Darwin and non-Linux desktop paths unaffected.
- Preserve the local NixOS integration boundary for Caelestia instead of importing upstream Home Manager as the primary owner.
- Avoid reintroducing end4 or another fallback shell.
- Keep the change minimal and focused on runtime integration, not visual redesign.

## Risks

- Caelestia may have additional runtime helper binaries that only appear through interactive UI paths.
- The logind lock crash may require an upstream fix if avoiding logind-triggered Caelestia locking is insufficient.
- Large wallpaper decode behavior may still fail if Caelestia's image cache rejects `/home/c1/the-great-sage.jpg`; this task can seed ownership but may need a follow-up image conversion if upstream decoding limits persist.
- Running validation outside the live Hyprland session cannot fully prove launcher and wallpaper rendering.

## Scope

- Update the local Caelestia module and Hyprland integration so Caelestia owns wallpaper for Axiom.
- Seed Caelestia wallpaper state/config from Nix-owned host wallpaper policy where appropriate.
- Fix `caelestia-shell.service` runtime PATH and duplicate-instance controls.
- Update Hyprland keybinds and lock command routing to avoid unmanaged shell launches and the observed logind lock crash path.
- Record validation evidence and runtime follow-up notes.

## Non-Goals

- Do not replace Caelestia Shell or change its upstream package source.
- Do not redesign the launcher UI or change the default application set beyond what is required for app execution.
- Do not solve unrelated boot failures such as the current `nixos-activation.service` GitHub DNS/JPM dependency failure.
- Do not fix unrelated autossh host key verification failures.

## Design Summary

- Prefer one wallpaper owner: Caelestia should own the background layer, so the old Hyprland `swaybg` hook should be disabled or gated when Caelestia is enabled.
- Make Caelestia's first boot deterministic by writing the wallpaper state file from Nix when a host wallpaper is configured.
- Treat `caelestia-shell.service` as the only long-running shell owner. Add duplicate protection and route shell restart keybinds through `systemctl --user`.
- Give the service an explicit runtime PATH for Caelestia UI subprocesses instead of relying on a shell/user profile PATH that systemd does not provide.
- Avoid `loginctl lock-session` as the ordinary idle/keybind lock path while Caelestia's logind lock surface is crashing; call `hyprlock` directly for now.

## Phases

- Phase 1: Contract and diagnostic evidence capture.
- Phase 2: Low-risk integration implementation in an isolated worktree.
- Phase 3: Static validation of Nix evaluation and rendered config.
- Phase 4: Review, walkthrough, and wiki writeback with live-session follow-up notes.
