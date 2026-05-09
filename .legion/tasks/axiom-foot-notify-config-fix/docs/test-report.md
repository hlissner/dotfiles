# Test Report: Axiom Foot Notify Config Fix

> Date: 2026-05-09
> Worktree: `.worktrees/axiom-foot-notify-config-fix/`
> Branch: `legion/axiom-foot-notify-config-fix`

## Summary

PASS. The reported Foot startup failure was reproduced from the repository source `config/foot/foot.ini`, which is linked into the generated Home Manager path as `foot/foot.global.ini`. Removing the unsupported `[main].notify` key makes both the source config and the Nix-evaluated global config validate under Foot 1.25.0.

## Failure Reproduction

Command before the patch:

```sh
foot --check-config --config config/foot/foot.ini
```

Result: FAIL.

Key evidence:

```text
err: config.c:1126: config/foot/foot.ini:5: [main].notify: notify-send -a ${app-id} -i ${app-id} ${title} ${body}: not a valid option: notify
```

Why this matters: `modules/desktop/term/foot.nix` links `config/foot/foot.ini` as `foot/foot.global.ini`, matching the live failure path reported by the user.

## Validation

Command:

```sh
foot --check-config --config config/foot/foot.ini
```

Result: PASS.

Why this matters: this directly validates the edited repository Foot config with the installed Foot binary.

Command:

```sh
src=$(env -u DOTFILES_HOME nix eval --impure --raw .#nixosConfigurations.axiom.config.home.configFile.'"foot/foot.global.ini"'.source) && foot --check-config --config "$src"
```

Result: PASS.

Why this matters: this validates the exact Nix-evaluated source path that Home Manager uses for `foot/foot.global.ini`, not only the working-tree file.

Command:

```sh
git diff --check
```

Result: PASS.

Command:

```sh
env -u DOTFILES_HOME nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

## Warnings

The Nix commands emitted existing repository/channel warnings:

- `specialArgs.pkgs` means some nixpkgs options/overlays are ignored.
- `mesa.drivers` is deprecated.
- `hardware.pulseaudio` has been renamed to `services.pulseaudio`.
- `system` has been renamed to/replaced by `stdenv.hostPlatform.system`.

These warnings did not prevent the final build.

## Skipped Live Checks

- The fixed generation was not switched into the live system from this PR worktree.
- After deployment, open Foot from the normal launcher/keybind path and confirm it no longer aborts on `foot.global.ini`.
