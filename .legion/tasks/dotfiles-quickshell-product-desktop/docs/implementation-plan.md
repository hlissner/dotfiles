# Implementation Plan

## Milestone 1: Local Quickshell Shell And Ownership

### Scope

- `modules/desktop/quickshell.nix`
- `config/quickshell/**`
- `hosts/axiom/default.nix`

### Steps

- [ ] Replace default `dms run` service with a local `quickshell` service for the product shell.
- [ ] Add repository-owned Quickshell QML/config for a left-side Isabel-like dock/status/control surface.
- [ ] Ensure required runtime packages are available: Quickshell, Qt image/icon dependencies, network/audio/Bluetooth GUI tools, file manager dependencies.
- [ ] Stop enabling Rofi by default for Axiom.

### Verification

- Command: targeted `nix eval` proving Quickshell service/config is enabled for Axiom.
- Expected: `dms run` is not the default product shell and Axiom has local Quickshell config linked.

### Rollback Notes

- Disable `modules.desktop.quickshell.enable` or revert the PR.

## Milestone 2: Isabel-like Hyprland Defaults And GUI Entry Points

### Scope

- `modules/desktop/hyprland.nix`
- `config/hypr/hyprland.conf`
- `modules/themes/autumnal/hyprland.nix`
- `hosts/axiom/default.nix`

### Steps

- [ ] Move visual defaults toward Isabel: gaps, rounding, blur, shadows, border colors, app-friendly floating rules.
- [ ] Replace primary `hey @rofi` bindings with direct app/help/GUI actions.
- [ ] Ensure GUI entry points exist for browser, files, terminal, power, audio, Wi-Fi, Bluetooth, notifications/help, screenshot, and lock.
- [ ] Keep UWSM/session bootstrap and validated Hyprland 0.53 syntax.

### Verification

- Command: generated full Hyprland config plus `Hyprland --verify-config`.
- Expected: config parses and no primary Hyprland path requires Rofi.

### Rollback Notes

- Restore previous Hyprland config generation or revert PR.

## Milestone 3: Documentation, Cleanup, Build Validation

### Scope

- `docs/axiom-desktop.md`
- stale desktop config payloads such as `config/ncmpcpp/`
- Legion verification/review docs

### Steps

- [ ] Add user-facing desktop guide with visible UI, GUI entry points, shortcuts, and troubleshooting.
- [ ] Remove stale unreferenced desktop payloads that contradict the new direction.
- [ ] Run `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel` and fix in-scope failures.
- [ ] Record verification evidence, readiness review, walkthrough, and wiki writeback.

### Verification

- Command: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Expected: build succeeds.

### Rollback Notes

- Revert PR or switch to previous NixOS generation.
