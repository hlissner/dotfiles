# Test Report: axiom-caelestia-keybind-fix

## Summary

- Result: PASS
- Scope: focused Caelestia migration runtime fixes for the reported top-level `catchall` Hyprland parse error and checkerboard placeholder icons.
- Environment: headless automation shell; no live Wayland/Hyprland session variables were available for graphical smoke testing.

## Commands

| Check | Command | Result | Evidence |
|---|---|---|---|
| Upstream README/Nix reference | `gh api repos/caelestia-dots/shell/readme --jq .content \\| base64 -d`; `gh api repos/caelestia-dots/shell/contents/nix/default.nix --jq .content \\| base64 -d`; `gh api repos/caelestia-dots/shell/contents/nix/hm-module.nix --jq .content \\| base64 -d` | PASS | README confirms Nix `with-cli`; upstream package wraps runtime deps/fonts but does not expose icon-theme/MIME fallback packages. |
| Generated keybind text | `nix eval --raw --impure '.#nixosConfigurations.axiom.config.home.configFile."hypr/custom/keybinds.conf".text'` | PASS | Output no longer contains `bindin = Super, catchall, ...`; Caelestia launcher/sidebar/media/screenshot/record/clipboard/app/workspace bindings remain. |
| Source regression search | `grep` tool for `catchall` under `modules/desktop/*.nix` | PASS | No `catchall` remains in generated desktop module sources. |
| Caelestia runtime packages | `nix eval --impure --json --expr '<filter Axiom users.users.c1.packages names>'` | PASS | Evaluated user packages include `caelestia-shell-1.0.0`, `caelestia-cli-...`, `hicolor-icon-theme-0.18`, `adwaita-icon-theme-49.0`, `papirus-icon-theme-20250501`, `shared-mime-info-2.4`, and `xdg-utils-1.2.1`. |
| Hyprland parser | Assembled generated Axiom Hyprland config with Nix `writeText`, then ran evaluated `Hyprland --verify-config --config <assembled-config>` | PASS | Hyprland returned `config ok`, directly covering the reported parser surface. |
| Diff hygiene | `git diff --check` | PASS | No whitespace errors. |
| Axiom build | `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` | PASS | Axiom system toplevel build completed after rebuilding the generated keybind Home Manager file. |

## Notes

- Nix emitted existing non-blocking warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`.
- `Hyprland --verify-config` emitted the expected warning about launching without `start-hyprland`; parser result was still `config ok`.
- Live Caelestia launcher interruption behavior and icon rendering were not exercised because the validation shell is not a running Wayland session.
