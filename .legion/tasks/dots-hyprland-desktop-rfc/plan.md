# Dots Hyprland Desktop Complete End4 Import

## Task Identity

- Name: Dots Hyprland Desktop Complete End4 Import
- Task ID: `dots-hyprland-desktop-rfc`
- Continuation target: complete the end4 desktop migration instead of shipping a substrate-only downgrade.
- Upstream source: `https://github.com/end-4/dots-hyprland`
- Current source of truth: this contract, `docs/rfc.md`, the user-provided `end4.md` requirements already folded into task docs, and upstream end4 files imported in this iteration.

## Goal

Make Axiom load and use the end4 `ii` Quickshell desktop path from the repository, not the old Axiom shell or a Phase 4-only service substrate. The completed state must include the upstream `ii` shell family, end4-aligned Hyprland layering, matugen/theme/wallpaper chain, and Phase 4 core service/UI surfaces wired through NixOS.

## Problem

PR #18 correctly declared many Phase 4 services but explicitly downgraded the deliverable to substrate-only because `config/quickshell/ii/shell.qml` was missing. The user rejected that downgrade and pointed to the upstream end4 repository as the missing source. Continuing without importing and wiring `ii` would keep the old Axiom shell alive as the de facto UX, which conflicts with `end4.md` and the explicit user instruction.

## Acceptance Criteria

- The repository contains the imported end4 Quickshell `ii` source required for `quickshell --config ii` to resolve `ii/shell.qml` and default to `IllogicalImpulseFamily`.
- Axiom's Quickshell module defaults to the end4 `ii` config path, not `axiom-shell`.
- The old Axiom shell is no longer the active runtime config; if any legacy files remain, they are not linked as the default shell and are documented as obsolete or removed.
- The repository contains end4-aligned matugen/theme/wallpaper sources and scripts needed by the `ii` shell to find theme templates and color scripts.
- The repository contains end4-aligned Hyprland source layering for `hyprland.conf`, `hyprland/*`, `hypridle.conf`, `hyprlock.conf`, and custom/Nix-generated override files.
- Nix still owns host-specific monitor/workspace/default-app facts, UWSM/greetd/portal startup, Quickshell user service, keyring/polkit, cliphist, power profiles, i2c/DDC, and runtime packages.
- Phase 4 UI surfaces from end4 `ii` are retained in source scope: left/right sidebars, overview, launcher/search, notifications, OSD, wallpaper selector, session/lock, and polkit-facing UX.
- `systemctl --user restart quickshell.service` can be attempted in the actual Axiom user environment; if a live graphical session is unavailable from the tool shell, the report must clearly distinguish host identity from session environment and run all feasible static/build checks.
- Nix evaluation/build evidence is recorded, plus any Quickshell/Hyprland static validation that can run without a live compositor.
- Legion closing artifacts and PR lifecycle are completed again.

## Assumptions

- The current machine is Axiom, but the command shell may still be a TTY/non-Hyprland session; live Wayland validation depends on `WAYLAND_DISPLAY` and `HYPRLAND_INSTANCE_SIGNATURE`, not hostname alone.
- Upstream end4 files are the required missing source for the rejected substrate downgrade.
- It is acceptable to vendor upstream shell/config sources into this dotfiles repository, provided no unmanaged setup script, secrets, generated runtime state, or live home-directory writes become the source of truth.
- The import may be large; correctness and reaching the declared end4 runtime path matter more than preserving old Axiom shell compatibility.

## Constraints

- Do not run upstream end4 `setup`.
- Do not commit API keys, generated color outputs, live cache/state, machine-local secrets, or upstream installer artifacts that mutate home directly.
- Do not keep `autumnal` or old Axiom shell visuals as desktop truth.
- Keep Darwin isolation.
- Keep Axiom host facts declarative in Nix.
- Keep Phase 5 visual automation and Phase 6 AI policy out of mandatory acceptance unless their source files are needed for imported `ii` QML to load; cloud/API functionality must remain inert without keys/policy.

## Scope

- Fetch upstream `end-4/dots-hyprland` in the isolated worktree and import the required `dots/.config` sources into repository-managed `config/` paths.
- Replace Axiom's active Quickshell config default with `ii` and remove/demote the old `axiom-shell` runtime path.
- Add or adjust Nix linking for `quickshell/ii`, `matugen`, Hyprland config, state directories, runtime packages, services, and host override files.
- Update RFC/task docs from substrate-only to complete end4 import.
- Run build/static validation and live-session validation where the environment permits.
- Complete review, walkthrough, wiki writeback, commit, PR, checks/review, cleanup, and main refresh.

## Non-Goals

- Do not design or enable cloud/API/key-backed AI behavior beyond making source files available if required by `ii` imports.
- Do not make mutable generated color files Nix-store-managed.
- Do not preserve old Axiom guide/dock/button behavior.
- Do not complete Phase 5 screenshot/OCR/translation/cloud visual search as a separate product milestone unless those files are imported as passive dependencies of the `ii` source tree.

## Design Summary

- Treat the end4 upstream tree as the missing product source, not merely inspiration.
- Vendor the end4 `ii` shell and its required adjacent config/scripts into repository-managed `config/` paths.
- Nix deploys imported sources into XDG config locations and owns all system integration.
- Host-generated custom overrides adapt end4 to Axiom: monitors, workspaces, default apps, env, keybind fallbacks, service startup, and hardware facts.
- Verification should prove both the Nix composition and the concrete presence/loadability of `ii/shell.qml`; live UI verification is attempted only when the tool environment has the necessary Wayland/Hyprland session variables.

## Risks

- Upstream `ii` has broad QML imports and runtime assumptions; missing packages may only surface during Quickshell startup.
- Importing large upstream source increases review size and future maintenance cost.
- Some end4 modules may assume Arch-style commands, KDE tools, or mutable config files; Nix wrappers/overrides may be required.
- Live Quickshell validation can still fail in a TTY even on host `axiom`.
- Imported AI/cloud/OCR modules can create privacy/security concerns if enabled without policy; they must stay inert unless explicitly configured later.

## Phases

- Brainstorm/restore: rewrite the contract so complete end4 import is required and substrate-only is invalid.
- Spec RFC: update RFC to reflect direct upstream import and integration boundaries.
- Review RFC: confirm the direct-import design is acceptable before implementation.
- Engineer: import upstream files, wire Nix/Hyprland/Quickshell, and remove/demote old shell runtime.
- Verify Change: run Nix build/eval, static checks, and live-session checks where possible.
- Review Change: assess readiness, scope, and security/privacy impact.
- Report Walkthrough: generate implementation walkthrough and PR body.
- Legion Wiki: update current truth and maintenance backlog.
- PR Lifecycle: commit, rebase, push, open PR, attempt auto-merge, follow checks/review, cleanup, and refresh main workspace.
