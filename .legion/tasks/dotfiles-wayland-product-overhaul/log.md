# Implementation Log

## 2026-05-08

- Read approved `plan.md`, RFC, implementation plan, and RFC review from the main workspace before editing.
- Determined pinned nixpkgs/unstable has DMS, Quickshell, Matugen, Discord/Vesktop, and Umu, but not Zen; added narrow `zen-browser` flake input.
- Removed obsolete desktop/service/browser/media modules and migrated active workstation hosts away from X11/bspwm and LibreWolf/Chrome/Edge baseline references.
- Implemented Hyprland UWSM/greetd, portal, DMS/Quickshell service, Matugen template, Hyprland product rules, mpv, Discord/Vesktop, Steam, Wi-Fi, and Bluetooth changes.
- Verification found residual legacy config/theme files plus Spotify/Spicetify wiring; removed the stale paths, host enables, flake input/locks, and Spotify-specific Hyprland keybindings.
- Validation also found that new Git flake module files must be tracked before Nix sees them; marked the new modules intent-to-add before rerunning option checks.
- Fixed validation-discovered implementation issues: removed the broken `xwaylandvideobridge` package alias from the Discord module and narrowed the desktop-environment assertion so DMS/Quickshell is not counted as a second desktop environment.
- Fixed readiness-review finding: Zen defaults now use the selected package's `zen-beta` executable, `zen-beta.desktop` MIME ID, and `zen-beta` Hyprland window class.
- Fixed re-review finding: removed remaining host-level `default = "zen"` overrides on `azar`, `atlas`, and `axiom`; all Zen-enabled hosts now evaluate to `zen-beta`.
- Review-change stage PASS with no remaining blocking findings; residual risks are agenix dry-run blocker, deferred manual runtime checks, and deferred Darwin runtime validation.
- Report-walkthrough stage produced `docs/report-walkthrough.md` and `docs/pr-body.md` for reviewer handoff.
- Legion wiki writeback added task summary plus durable decisions/patterns for the new Linux workstation desktop baseline and Git flake validation with new module files.
- Verification: `nix flake show`, retained NixOS host evaluations, key option checks, legacy searches, and Darwin boundary searches passed; full dry-run build is blocked only by the pre-existing agenix host-key requirement on this machine.
