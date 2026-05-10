# Implementation Plan: axiom-caelestia-shell-migration

## Milestone 1: Prepare Worktree And Input

- Open isolated worktree on `legion/axiom-caelestia-shell-migration`.
- Add `caelestia-shell` flake input following `nixpkgs-unstable`.
- Update lockfile for the new input.

## Milestone 2: Replace Shell Integration

- Remove or replace `modules/desktop/quickshell.nix` so no active option starts end4 `ii`.
- Add `modules/desktop/caelestia.nix` with local NixOS-owned service/config/package integration.
- Update `modules/desktop/hyprland.nix` to default-enable Caelestia and remove end4 `quickshellCfg` coupling.

## Milestone 3: Rebuild Hyprland Runtime Config

- Rewrite generated env/variables/execs/keybinds to remove IllogicalImpulse and `qs -c ii` assumptions.
- Introduce Caelestia global shortcuts and CLI command fallbacks using absolute package paths where possible.
- Keep monitor/workspace/input/rules generated from Axiom host facts.
- Simplify checked-in `config/hypr/hyprland.conf` and remove end4 imported source layers.

## Milestone 4: Delete Superseded Source

- Delete `config/quickshell/ii`.
- Delete `config/matugen` unless implementation finds an active non-end4 consumer.
- Delete `config/fuzzel` unless retained as a deliberate non-end4 fallback.
- Delete root `end4.md`.
- Delete or rewrite end4-specific `hypridle`/`hyprlock` dispatches.

## Milestone 5: Validate And Close

- Run targeted Nix evals for service command, package path, generated config, and absence of active end4 references.
- Run Axiom toplevel build or document the strongest available blocked command.
- Run static checks and live-session smoke if environment permits.
- Complete review-change, walkthrough/PR body, wiki writeback, commit/PR lifecycle, cleanup, and main refresh.
