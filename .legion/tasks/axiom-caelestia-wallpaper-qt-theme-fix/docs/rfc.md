# RFC: Axiom Caelestia Wallpaper Decode And Qt Theme Fix

## Status

- Proposed for implementation
- Task: `axiom-caelestia-wallpaper-qt-theme-fix`
- Base ref: `origin/master`
- Worktree: `.worktrees/axiom-caelestia-wallpaper-qt-theme-fix`
- Branch: `legion/axiom-caelestia-wallpaper-qt-theme-runtime`

## Context

PR #25 made Caelestia the only intended Axiom wallpaper owner and fixed service ownership/runtime PATH issues. Live validation then narrowed the remaining black wallpaper to Caelestia/Qt rejecting `/home/c1/the-great-sage.jpg`:

- Source dimensions: `11846x5733`
- Approximate 4-channel decoded allocation: `271652472` bytes, about `259 MiB`
- Qt image IO default allocation limit observed in logs: `256 MB`

The launcher icon color blocks match upstream Caelestia issue `caelestia-dots/shell#1282`. A contributor reports that replacing `QT_QPA_PLATFORMTHEME=qtengine` with `QT_QPA_PLATFORMTHEME=qt6ct` or `qt5ct` in Hyprland env config and restarting Hyprland fixed the issue.

## Decision

Implement two bounded integration fixes:

- Generate a decode-safe runtime wallpaper derivative from `/home/c1/the-great-sage.jpg` for Caelestia and seed Caelestia state to that derivative when the current state is missing, empty, or still points at the oversized canonical source.
- Set `QT_QPA_PLATFORMTHEME=qt6ct` in the repo-owned Hyprland env and UWSM env, and install `qt6ct` with the Caelestia desktop session packages.

## Wallpaper Design

The existing `caelestia-seed-wallpaper` service pre-start script should become responsible for preparing the runtime-safe asset when Caelestia wallpaper ownership is enabled and a wallpaper source path is configured.

Recommended behavior:

- Keep `modules.theme.wallpapers."*".path = "/home/c1/the-great-sage.jpg"` as the canonical host wallpaper source.
- Create a derivative under Caelestia's existing wallpaper state directory, for example `/home/c1/.local/state/caelestia/wallpaper/generated.jpg`.
- Use ImageMagick from the Nix store to downscale only if needed with a 3840x2160 bound, preserving aspect ratio and stripping metadata.
- Regenerate the derivative when it is missing or older than the source.
- Write Caelestia's `path.txt` to the derivative when `path.txt` is missing, empty, or equals the oversized canonical source.
- Do not overwrite `path.txt` if the user has manually selected a different wallpaper.
- Fall back to the canonical source only if conversion cannot produce a derivative and no state file exists; this preserves prior behavior while leaving logs actionable.

This keeps the large source as the policy input while giving Caelestia/Qt a predictable decode-safe runtime input.

## Qt Theme Design

The repo already generates `hypr/custom/env.conf` and `uwsm/env`. Add the upstream workaround there:

- `env = QT_QPA_PLATFORMTHEME,qt6ct` in generated Hyprland env config.
- `export QT_QPA_PLATFORMTHEME=qt6ct` in generated UWSM env.
- Add `pkgs.qt6ct` to desktop/session packages so the platform theme plugin exists.
- Keep `QT_QPA_PLATFORM=wayland` in `caelestia-shell.service`.

The issue comment says a Hyprland restart is required. A config reload is not enough to prove launcher icon rendering because already-started processes inherit their original environment.

## Alternatives

### Raise Qt Image Allocation Limit

Set a service-local `QT_IMAGEIO_MAXALLOC` large enough for the source image. This is the smallest possible wallpaper change, but it makes Caelestia accept larger image decodes instead of fixing the oversized runtime input. Because the source image is only slightly over the default limit, it would likely work, but it weakens a Qt safety boundary and does not scale as well if future wallpapers are larger.

### Build-Time Nix Derivative

Create the derivative as a Nix derivation. This would make the output immutable and reproducible when the source is in the store, but the current source is an absolute host-local file under `/home/c1`. Reading it in a derivation would make the build more impure and potentially sandbox-sensitive. Runtime generation matches the current mutable Caelestia state model better.

### Restore `swaybg`

This is out of scope and conflicts with the prior user decision that Caelestia should own wallpaper.

## Rollback

- Remove the generated derivative logic and restore the previous seed behavior that writes the configured wallpaper source directly.
- Remove `QT_QPA_PLATFORMTHEME=qt6ct` from generated Hyprland/UWSM env and remove the `qt6ct` package addition.
- Keep PR #25's one-owner wallpaper and systemd service ownership decisions unless a separate task changes that policy.

## Verification Plan

- Evaluate generated Axiom values for:
  - Caelestia `ExecStartPre` exists when wallpaper ownership is enabled.
  - `hypr/custom/env.conf` contains `QT_QPA_PLATFORMTHEME,qt6ct`.
  - `uwsm/env` exports `QT_QPA_PLATFORMTHEME=qt6ct`.
  - `qt6ct` is included in Axiom packages.
- Build `.#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure`.
- After deployment and Hyprland restart, live checks should confirm:
  - Caelestia `path.txt` points at the generated derivative unless the user selected another wallpaper.
  - Caelestia logs no longer include the Qt allocation rejection for the active wallpaper.
  - `pgrep -a swaybg` remains empty.
  - One Caelestia shell quickshell instance is active.
  - Launcher icons no longer render as color blocks.
