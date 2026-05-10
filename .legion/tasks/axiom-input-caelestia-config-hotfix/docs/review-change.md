# Review Change

## Verdict

PASS

## Blocking Findings

None.

## Scope Check

The implementation is limited to the approved hotfix scope:

- `modules/desktop/hyprland.nix` canonicalizes generated Hyprland modifier tokens in existing bindings only.
- `modules/desktop/caelestia.nix` changes the Caelestia `shell.json` ownership model from immutable Home Manager text to a service-seeded mutable user file, and adds the default `utilities.toasts.kbLayoutChanged = false` seed setting.
- Legion task evidence is contained under `.legion/tasks/axiom-input-caelestia-config-hotfix/**`.

No end4, fuzzel, `catchall`, global shortcut DBus rewrite, wallpaper ownership change, physical keyboard mapping change, or unrelated desktop application change is present.

## Correctness And Maintainability

- Generated keybinds now use canonical `SUPER`, `CTRL`, `ALT`, and `SHIFT` modifier spelling while preserving the existing command targets.
- Generated input config still emits `kb_layout = us` and `kb_variant = colemak` for Axiom.
- Home Manager no longer owns `caelestia/shell.json`, avoiding the Nix-store symlink that made the file read-only.
- The Caelestia user service seeds `shell.json` before startup, replacing only a missing file or a symlink that resolves under `/nix/store`; real files and arbitrary user symlinks are left untouched.
- The seed JSON contains the previous minimal Caelestia defaults plus `utilities.toasts.kbLayoutChanged = false`.
- Verification passed for generated assertions, seed script/JSON inspection, Hyprland parser validation, Axiom toplevel build, and diff whitespace.

## Security Lens

Applied because the change touches user-writable config creation from a systemd user service.

- The service runs as the user, writes only under `/home/c1/.config/caelestia`, and does not add privilege escalation, auth, network, token, secret, or tenant/data exposure behavior.
- The symlink replacement guard is restricted to `/nix/store/*`, so it targets the old immutable Nix output path and avoids clobbering an arbitrary user-managed symlink.
- Existing real user config files are not overwritten on service restart or rebuild.

No security-blocking issue was identified.

## Residual Risks

- Static checks cannot prove the physical Super key works in the live Axiom Hyprland session; deploy and smoke-test `SUPER+Space`, `SUPER+Enter`, and workspace bindings after switching.
- If live `hyprctl -j devices` still reports `active_keymap` as unknown, the toast suppression will hide the noisy notification but a separate runtime/upstream input investigation may still be needed.
- Existing Nix warnings about `specialArgs.pkgs`, `mesa.drivers`, `hardware.pulseaudio`, and `system` rename remain unrelated to this task.

## Evidence

- `.legion/tasks/axiom-input-caelestia-config-hotfix/docs/test-report.md`
- `git diff -- modules/desktop/caelestia.nix modules/desktop/hyprland.nix`
