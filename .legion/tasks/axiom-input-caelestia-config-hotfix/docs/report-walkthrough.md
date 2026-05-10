# Report Walkthrough

## Mode

implementation

## Summary

- Canonicalized generated Axiom Hyprland modifier tokens to `SUPER`, `CTRL`, `ALT`, and `SHIFT` while keeping existing keybind actions intact.
- Changed Caelestia `shell.json` from an immutable Home Manager-managed file to a mutable user config seeded by `caelestia-shell.service` before startup.
- Added a repo-owned default seed setting to disable Caelestia keyboard layout change toasts, avoiding boot-time `Unknown` layout notifications by default.

## Changed Files

- `modules/desktop/hyprland.nix`: generated keybind text now uses canonical uppercase modifier names accepted by Hyprland.
- `modules/desktop/caelestia.nix`: default shell settings include `utilities.toasts.kbLayoutChanged = false`; `caelestia/shell.json` is no longer emitted through Home Manager; the Caelestia service seeds a writable config file when missing or when an old symlink points into `/nix/store`.

## Behavior Notes

- Existing real `~/.config/caelestia/shell.json` files are preserved on restart/rebuild.
- Arbitrary user-managed symlinks are preserved; only Nix-store symlinks are replaced.
- Wallpaper seeding and Caelestia service ownership remain unchanged.

## Verification

- PASS: focused `nix eval` assertions for uppercase keybinds, retained `kb_layout = us` / `kb_variant = colemak`, removed Home Manager ownership of `caelestia/shell.json`, and Caelestia pre-start hooks.
- PASS: inspected realized seed script and seed JSON, including the `/nix/store` symlink guard and `kbLayoutChanged=false` seed value.
- PASS: assembled generated Hyprland config with the evaluated Hyprland package; result `config ok`.
- PASS: `nix build --impure '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`.
- PASS: `git diff --check`.

## Review Result

- PASS: `docs/review-change.md` found no blocking correctness, scope, maintainability, or security issue.

## Residual Risk

- Live Super-key behavior and boot toast behavior still require a real Axiom Hyprland session after deployment because this automation context has no `HYPRLAND_INSTANCE_SIGNATURE`.
- If live `hyprctl -j devices` still reports an unknown active keymap, this hotfix suppresses the noisy default toast but does not replace a future runtime/upstream input investigation.

## Evidence Links

- `plan.md`
- `docs/test-report.md`
- `docs/review-change.md`
