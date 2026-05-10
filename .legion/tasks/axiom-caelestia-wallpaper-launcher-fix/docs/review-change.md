# Change Review: Axiom Caelestia Wallpaper And Launcher Fix

## Decision

PASS

## Blocking Findings

- None.

## Scope Review

- The implementation stays within the approved scope: Caelestia wallpaper ownership, first-start wallpaper state seeding, service PATH/duplicate-instance controls, and lock/restart routing.
- Unrelated logged failures such as `nixos-activation.service` DNS/JPM failures and autossh host key failures were not modified.

## Correctness Review

- Caelestia wallpaper ownership is explicit for Axiom via `modules.desktop.caelestia.wallpaper.enable = true`.
- The old `swaybg` hook is gated behind `!caelestiaOwnsWallpaper`, so Axiom no longer has two wallpaper owners.
- Wallpaper state is seeded from `ExecStartPre` only when the state file is missing or empty, so Caelestia can still update its mutable wallpaper state later.
- The shell service uses `--no-duplicate` and restart keybinds call `systemctl --user`, preventing new unmanaged quickshell processes through repository-owned keybinds.
- The service PATH includes `app2unit`, `util-linux`, and merged user packages, covering the observed launcher/helper command failures.

## Security Lens

Security lens applied because the change touches lock/session behavior.

- No exploitable trust-boundary issue found. The changed ordinary lock path calls `hyprlock`, the existing configured lock command, instead of routing through Caelestia's crashing logind lock handler.
- Residual security consideration: direct `hyprlock` should be live-tested after deploy to confirm it locks before sleep and idle exactly as expected on Axiom.

## Verification Review

- `docs/test-report.md` contains targeted Nix evaluation evidence for generated wallpaper, service, keybind, and hypridle values.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure` passed, proving the full Axiom configuration composes.

## Non-Blocking Notes

- If Caelestia still cannot decode `/home/c1/the-great-sage.jpg` in the live session, the next smallest follow-up is to generate a display-sized wallpaper asset while keeping Caelestia as owner.
