# RFC: Axiom Desktop Session PATH And Steam Fix

## Status
Draft for `review-rfc`.

## Context
The `axiom` graphical desktop can open Foot, but commands such as `git` and `awk` are missing inside that desktop-launched terminal. SSH login does not reproduce the issue, so the failure is likely caused by the graphical session's inherited command environment rather than missing host packages.

Targeted evals of the current generated configuration show:

- `config.environment.sessionVariables.PATH` is absent.
- `config.environment.variables.PATH` is only `"$HOME/.opencode/bin:$PATH"`, which does not establish a complete GUI session path.
- Generated `uwsm/env` exports desktop variables but not `PATH`.
- `caelestia-shell.service` uses an explicit `path`, but that path is currently based on Caelestia helpers plus `config.users.users.c1.packages`; it does not include the full system package closure.
- `git`, `gawk`, `steam`, and `steam-run` are present in `config.environment.systemPackages`.

This makes the most likely failure mode a session inheritance bug: Hyprland/UWSM, Caelestia, app2unit-launched apps, and Foot child shells do not all receive the same command path that SSH/login shells receive.

## Options

### Option A: Patch only the terminal command or shell rc
Add shell-specific startup logic or change the Foot command so desktop-launched terminals repair `PATH` when they start.

Pros:
- Narrow apparent blast radius.
- Could make the reported Foot symptom disappear quickly.

Cons:
- Does not fix Caelestia launcher children, app2unit-launched apps, Steam, Thunar, or other GUI app paths.
- Treats a session ownership problem as a terminal-local problem.
- Depends on shell startup semantics; non-login shells may still differ from SSH login shells.

### Option B: Export a deterministic session PATH through UWSM and import it into systemd user
Generate a login-like command path for the graphical session, export it from `uwsm/env`, and include `PATH` in the `systemctl --user import-environment` startup hook.

Pros:
- Fixes the compositor/session environment at the right layer.
- Covers Hyprland-spawned processes and app2unit/systemd-user launches after the startup hook imports the variable.
- Preserves the existing UWSM `start-hyprland` startup model.

Cons:
- Does not by itself fix services that deliberately override `PATH` through their own `path` option.
- Needs generated-config validation because the physical GUI session cannot be proven here.

### Option C: Extend Caelestia service path with system packages
Keep Caelestia's explicit runtime path, but add the generated `config.environment.systemPackages` alongside Caelestia helpers and user packages.

Pros:
- Directly addresses Caelestia as a launcher/helper process parent.
- Makes Caelestia-launched Foot inherit a path that includes `git`, `gawk`, and Steam wrappers.
- Matches existing wiki guidance that Caelestia requires explicit runtime PATH ownership.

Cons:
- Still needs Option B for Hyprland/UWSM and systemd-user manager environment consistency.
- Increases the Caelestia service PATH, though it reuses the already-generated system package closure rather than adding new packages.

### Option D: Use absolute commands for Steam, Foot, and selected launchers
Change specific app commands to absolute Nix store paths or package wrappers.

Pros:
- Avoids relying on PATH lookup for selected apps.
- Good for a small number of fixed service `ExecStart` commands.

Cons:
- Does not fix terminal child command lookup.
- Does not scale to desktop entries and user-launched commands.
- Leaves the underlying session environment broken.

## Decision
Use Option B and Option C together.

Implementation should:

- Define a generated desktop command path for Hyprland/UWSM that includes the user's local bin, per-user profile, current system profile, default Nix profile, and wrapper bin locations.
- Export that command path from generated `uwsm/env` so Hyprland and compositor-spawned commands inherit it.
- Add `PATH` to the existing `systemctl --user import-environment` call in the Hyprland startup hook so systemd-user services and app2unit launches receive the same path.
- Extend `caelestia-shell.service.path` with `config.environment.systemPackages` while preserving Caelestia CLI, `app2unit`, `util-linux`, and user packages.
- Keep Steam enablement unchanged; validate Steam package/launcher availability through generated config and leave live Steam startup logs as deployment evidence.

## Security Boundary
- No credentials, SSH settings, remote tunnel settings, or user identity settings change.
- The generated PATH should only reference existing profile/wrapper locations and declarative package closures.
- Do not add mutable shell startup edits or host-local one-off fixes outside the dotfiles.

## Rollback
Revert the changes to `modules/desktop/hyprland.nix` and `modules/desktop/caelestia.nix`, rebuild/switch `axiom`, and the system returns to the previous UWSM env and Caelestia service path. No data migration or user state cleanup is required.

## Verification
- Targeted eval: generated `uwsm/env` contains `export PATH=` with `/home/c1/.local/bin`, `/etc/profiles/per-user/c1/bin`, `/run/current-system/sw/bin`, `/nix/var/nix/profiles/default/bin`, and `/run/wrappers/bin`.
- Targeted eval: Hyprland startup hook imports `PATH` through `systemctl --user import-environment`.
- Targeted eval: `caelestia-shell.service.path` contains package names for `git`, `gawk`, `steam`, and `steam-run` in addition to Caelestia helpers.
- Targeted eval: `programs.steam.enable` remains `true` and Steam's generated package still exposes `steam` and `steam-run` wrappers.
- Full build: `nix build --impure --no-link path:$PWD#nixosConfigurations.axiom.config.system.build.toplevel` with `DOTFILES_HOME=$PWD` from the worktree, or record a precise blocker.
- Deployment checks: after switching on `axiom`, start a fresh Hyprland/UWSM session, open Foot from the GUI, confirm `command -v git`, `command -v awk`, and `echo $PATH`; launch Steam from the GUI and capture logs if it still fails.
