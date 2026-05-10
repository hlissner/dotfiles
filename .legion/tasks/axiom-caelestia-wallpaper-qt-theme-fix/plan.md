# Axiom Caelestia Wallpaper Qt Theme Fix

## Contract

- `name`: Axiom Caelestia Wallpaper Qt Theme Fix
- `taskId`: `axiom-caelestia-wallpaper-qt-theme-fix`

## Goal

Restore the live Axiom Caelestia session after the first wallpaper ownership fix by making the Caelestia wallpaper decodable at runtime and applying the upstream Qt platform theme workaround for launcher icon rendering.

## Problem

After Caelestia became the only wallpaper owner, the live session still turns black because Caelestia/Qt rejects `/home/c1/the-great-sage.jpg` as exceeding the current 256 MB decoded image allocation limit. That means ownership is now correct, but the chosen source image is too large for Caelestia's image cache path. The launcher also still shows colored icon blocks. Upstream Caelestia issue `caelestia-dots/shell#1282` reports the same icon-block symptom and a working fix: replace `QT_QPA_PLATFORMTHEME=qtengine` with `QT_QPA_PLATFORMTHEME=qt6ct` or `qt5ct` in the Hyprland environment, then restart Hyprland.

## Acceptance

- Axiom keeps Caelestia, not `swaybg`, as the wallpaper owner.
- Caelestia seeds and loads a wallpaper path that avoids the Qt decoded-image allocation failure seen for `/home/c1/the-great-sage.jpg`.
- The repository keeps `/home/c1/the-great-sage.jpg` as the canonical host wallpaper source while providing a display-safe runtime asset or equivalent decode-safe path for Caelestia.
- Hyprland/UWSM session environment sets `QT_QPA_PLATFORMTHEME=qt6ct` for the Caelestia desktop session, matching upstream issue #1282 guidance.
- Required qt6ct package support is available in the system/user environment without reintroducing `qtengine` or legacy end4/fuzzel paths.
- Static Nix validation proves the generated Axiom config paths, environment values, and service setup.
- Runtime-oriented notes document the required Hyprland restart boundary for the Qt theme change and the expected live checks.

## Assumptions

- The live Caelestia log message about `QImageIOHandler` is the current wallpaper black-screen root cause.
- A display-sized or otherwise compressed derivative of `/home/c1/the-great-sage.jpg` is acceptable as Caelestia's runtime wallpaper input if the original remains the canonical source.
- `qt6ct` is the preferred workaround because Caelestia and the current Qt stack are Qt 6 oriented, and `pkgs.qt6ct` is available.
- The old `qtengine` value may come from generated upstream Caelestia/UWSM environment or a user/session env file outside this repository; this task should make the repo-owned session environment win for Axiom.

## Constraints

- Do not restore `swaybg` for Axiom while Caelestia wallpaper ownership is enabled.
- Do not restore end4, fuzzel, or another legacy shell/launcher path.
- Keep changes focused on Axiom/Caelestia runtime integration, not a visual redesign.
- Do not modify unrelated boot/network/autossh issues.
- Preserve Darwin and non-Caelestia desktop behavior.

## Risks

- The upstream icon-block issue may have multiple causes; `qt6ct` is an evidence-backed workaround but may require a full Hyprland restart to validate.
- If the source wallpaper file changes shape or disappears, a generated runtime derivative must fail safely and leave actionable logs.
- Image conversion in Nix may require reading an absolute host-local file under `--impure`, matching the current host wallpaper policy.
- Live graphical validation remains necessary because static checks cannot prove Qt icon rendering or layer-shell image display.

## Scope

- Add a decode-safe Caelestia wallpaper path derived from Axiom's configured wallpaper source, or an equivalent minimal mechanism that avoids the Qt allocation limit.
- Update Caelestia wallpaper seeding so the service points at the decode-safe path when Caelestia owns wallpaper.
- Add `QT_QPA_PLATFORMTHEME=qt6ct` to the repo-owned Hyprland/UWSM session environment and ensure `qt6ct` is installed where needed.
- Validate generated Nix values and record the expected live restart/check procedure.

## Non-Goals

- Do not patch upstream Caelestia Shell unless the local integration fix cannot work.
- Do not make a broad Qt theming redesign beyond the platform theme variable and required package support.
- Do not change the chosen wallpaper image or replace it with an unrelated asset.
- Do not solve unrelated Caelestia lock crashes beyond preserving the prior `hyprlock` routing.

## Design Summary

- Keep the previous one-owner decision: Caelestia owns wallpaper, and Hyprland should not start `swaybg` for Axiom.
- Prefer a repo-owned display-safe wallpaper artifact for Caelestia over raising Qt allocation limits globally; this keeps the runtime fix bounded and avoids making every Qt image decode larger.
- Make the session-level Qt platform theme explicit in generated Hyprland/UWSM env so it wins over upstream `qtengine` defaults referenced by issue #1282.
- Keep validation split between static Nix checks and live-session checks that must happen after deploying and restarting Hyprland.

## Phases

- Phase 1: Materialize follow-up contract and capture upstream issue #1282 guidance.
- Phase 2: Enter isolated worktree and implement the bounded wallpaper/Qt environment changes.
- Phase 3: Run Nix evaluation/build validation and record generated config evidence.
- Phase 4: Review, walkthrough, wiki writeback, PR merge/cleanup, and main worktree refresh.
