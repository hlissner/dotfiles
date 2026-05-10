# Test Report: axiom-caelestia-shell-migration

Date: 2026-05-10

## Summary

Result: PASS for static/Nix validation. Live graphical smoke was skipped because this tool shell is not inside a Hyprland Wayland session.

The validation focused on the claims that matter for this migration: the active service starts Caelestia, the upstream CLI-enabled package is available, generated XDG/Hyprland config points at Caelestia rather than end4, active source no longer references end4 runtime paths, and the Axiom NixOS system still builds.

## Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `nix eval --raw github:caelestia-dots/shell#packages.x86_64-linux.with-cli.name` | PASS | Upstream package output exists and returned `caelestia-shell-1.0.0`. |
| `nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.serviceConfig.ExecStart'` | PASS | Evaluated service command points at `/nix/store/...-caelestia-shell-1.0.0/bin/caelestia-shell`. |
| `nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/caelestia/shell.json".text'` | PASS | Generated JSON contains minimal Nix-owned defaults: terminal `foot`, explorer `thunar`, playback `mpv`, audio `pavucontrol`, and `launcher.enableDangerousActions = false`. |
| `nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/custom/keybinds.conf".text'` | PASS | Generated keybinds use `caelestia:*` global shortcuts and CLI-backed commands such as `$caelestia screenshot`, `$caelestia record`, `$caelestia clipboard`, and `$caelestia emoji -p`. |
| `nix eval --impure --json --expr 'map (p: p.name or (builtins.baseNameOf (toString p))) (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.users.users.c1.packages'` | PASS | User packages include `caelestia-shell-1.0.0` and `caelestia-cli-7b8a4281aa8b2b12745de531cce0c65d87aea2e5`. |
| `rg -n 'quickshell --config ii|config/quickshell/ii|Illogical|ILLOGICAL|qsConfig|quickshell:|axiom-shell|matugen|fuzzel|end4|modules\.desktop\.quickshell' config modules README.md || true` | PASS | No active source matches in `config`, `modules`, or `README.md`. Historical `.legion/**` evidence was intentionally excluded from this active-runtime scan. |
| `git diff --check` | PASS | Initial run found trailing whitespace in `docs/rfc.md`; after fixing, rerun produced no output. |
| `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` | PASS | Axiom toplevel built successfully with the new Caelestia input, service unit, generated Home Manager files, and removed end4 source tree. |
| `if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then systemctl --user restart caelestia-shell.service && systemctl --user is-active caelestia-shell.service; else ...; fi` | SKIP | Output: `SKIP live Wayland smoke: WAYLAND_DISPLAY= HYPRLAND_INSTANCE_SIGNATURE=`. |

## Notes

- Nix eval/build emitted existing warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`; these are pre-existing repository/nixpkgs warnings and did not block evaluation or build.
- Hyprland runtime layer-shell behavior, Caelestia global shortcut delivery, and visual surfaces still need a post-deployment live session smoke because this shell lacks `WAYLAND_DISPLAY` and `HYPRLAND_INSTANCE_SIGNATURE`.
- Hyprland config syntax was indirectly covered by Nix-generated config evaluation and the toplevel build. A real `Hyprland --verify-config` run should be done after deployment or from an environment with the assembled Home Manager XDG config tree.
