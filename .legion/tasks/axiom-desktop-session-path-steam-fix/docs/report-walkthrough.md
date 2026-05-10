# Walkthrough: Axiom Desktop Session PATH And Steam Fix

## Mode
Implementation.

## Summary
- Fixes the `axiom` graphical session command environment by exporting a deterministic PATH from generated `uwsm/env`.
- Imports `PATH` into the systemd user manager during the Hyprland startup hook before `hyprland-session.target` starts.
- Extends `caelestia-shell.service.path` with `config.environment.systemPackages` so Caelestia-launched children and app2unit paths can resolve system packages such as `git`, `gawk`, `steam`, and `steam-run`.

## Changed Files
- `modules/desktop/hyprland.nix`: adds `desktopSessionPath`, exports it through `uwsm/env`, and imports `PATH` into systemd user startup.
- `modules/desktop/caelestia.nix`: extends the Caelestia service path with generated system packages while preserving existing helper and user package coverage.

## Design Evidence
- `docs/rfc.md`: chooses UWSM/systemd-user PATH propagation plus Caelestia service path extension over terminal-local shell fixes or app-specific absolute commands.
- `docs/review-rfc.md`: PASS; no blocking design findings.

## Verification Evidence
- `docs/test-report.md`: PASS for generated `uwsm/env`, Hyprland startup hook PATH import, Caelestia service path package coverage, Steam enablement, `git diff --check`, and full `axiom` toplevel build.
- Full build result: `DOTFILES_HOME="$PWD" nix build --impure --no-link path:$PWD#nixosConfigurations.axiom.config.system.build.toplevel` passed and produced `/nix/store/9gdi1kl212slpxiwbjmpkv410gi3kpkm-nixos-system-axiom-25.11.20260203.e576e3c.drv`.

## Review Evidence
- `docs/review-change.md`: PASS; no blocking findings.
- Security lens was applied because session command lookup changed; no credentials, identity, privileged service, SSH, or remote tunnel boundary changed.

## Deployment Checks
- Rebuild/switch `axiom`, then start a fresh Hyprland/UWSM session.
- Open Foot from the GUI and run `echo $PATH`, `command -v git`, and `command -v awk`.
- Launch Steam from the GUI; if it still fails, capture logs and handle it as a separate Steam runtime follow-up.
