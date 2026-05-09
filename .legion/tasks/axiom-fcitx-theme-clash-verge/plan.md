# Axiom Fcitx Theme And Clash Verge

## Goal
Fix the Fcitx5 Catppuccin theme so it is actually used on `axiom`, and add a reusable `clash-verge` desktop app module enabled only for `axiom`.

## Problem
The previous Fcitx5 change installed `catppuccin-fcitx5` and wrote a classic UI theme setting, but the live input method still does not show the Catppuccin theme. This likely means the effective Fcitx5 UI/theme config is incomplete or written to the wrong setting/file for the active Fcitx5 frontend. Separately, `axiom` needs Clash Verge installed through the dotfiles rather than manually.

## Acceptance
- `axiom` evaluates with Fcitx5 enabled and Catppuccin theme assets installed.
- The generated Fcitx5 config explicitly selects a Catppuccin Mocha theme in the effective classic UI configuration.
- If a user-level XDG config file is required for Fcitx5 to honor the theme, it is managed by the dotfiles and does not clobber private dictionaries.
- A reusable `modules.desktop.apps.clash-verge` option exists.
- `axiom` enables the reusable Clash Verge module.
- Focused Nix evaluation succeeds for `axiom`, or blockers are documented with evidence.

## Scope
- Inspect and adjust the existing `modules/desktop/input/fcitx5.nix` theme wiring.
- Add a reusable Clash Verge app module under `modules/desktop/apps`.
- Update `hosts/axiom/default.nix` to enable Clash Verge if the module is added.
- Add task-local Legion evidence, review, walkthrough, wiki writeback, and complete PR lifecycle.

## Non-goals
- Do not change the active global desktop theme.
- Do not redesign the Fcitx5 input engine setup beyond making the Catppuccin theme effective.
- Do not manage Clash proxy profiles, subscriptions, credentials, or service routing in this task.
- Do not alter private Fcitx/Rime user dictionaries.

## Assumptions
- Catppuccin Mocha should continue to use the `catppuccin-mocha-mauve` Fcitx5 theme variant unless a different accent is requested.
- Clash Verge installation means making the GUI package available through NixOS/home packages, not configuring a system proxy daemon.
- The package may be named `clash-verge-rev`, `clash-verge`, or live under unstable depending on nixpkgs; implementation should choose the package that evaluates in this flake.

## Constraints
- Work happens in `.worktrees/axiom-fcitx-theme-clash-verge` on branch `legion/axiom-fcitx-theme-clash-verge-input-proxy`.
- Base ref is `origin/master`.
- Keep changes minimal and compatible with existing hosts using `fcitx5-rime.enable`.

## Risks
- Fcitx5 may ignore system-level defaults if a pre-existing user config overrides the theme; this task can provide managed defaults, but live cleanup may require removing stale user config on `axiom`.
- Clash Verge runtime may need user profile/subscription setup after installation.

## Design Summary
Diagnose the generated Fcitx5 config shape and adjust the reusable module so Catppuccin Mocha is selected in the config path Fcitx5 actually reads. Add a small Clash Verge app module following existing desktop app module patterns, expose an enable option and package option, and enable it on `axiom`. Validate with focused Nix evals rather than broad rebuilds unless evaluation exposes package-level issues.

## Phases
1. Inspect Fcitx5 theme config generation and Clash Verge package availability.
2. Implement the smallest module/config changes.
3. Run focused Nix evaluation for `axiom` and compatibility where relevant.
4. Review change readiness and document evidence.
5. Complete PR lifecycle, cleanup, and main workspace refresh.
