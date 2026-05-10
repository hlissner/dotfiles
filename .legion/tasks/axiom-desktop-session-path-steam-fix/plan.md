# Axiom Desktop Session PATH And Steam Fix

## Task ID
`axiom-desktop-session-path-steam-fix`

## Goal
Fix the `axiom` graphical desktop session so terminals and GUI-launched apps inherit the expected Nix/user command `PATH`. Foot opened from the desktop must be able to find standard tools such as `git` and `awk`, and Steam launchability must be checked against the same session environment.

## Problem
On `axiom`, opening Foot from the graphical session reports missing commands such as `git` and `awk`. SSH login does not show the same problem, which strongly points at the desktop/session startup environment rather than missing packages in the host profile.

Steam also does not open. The current report cannot distinguish whether Steam fails because it is launched from the same broken GUI environment or because Steam has a separate runtime issue. The first repair should therefore restore the desktop session command environment and verify Steam's generated launcher/package shape before treating Steam as a separate application bug.

## Acceptance
- Foot launched from the `axiom` graphical desktop inherits a `PATH` that can resolve `git`, `awk`, and the expected user/system package commands.
- The generated Hyprland/UWSM/session environment imports or defines the same command path for compositor-spawned programs and systemd-user services that launch helpers.
- Caelestia launcher/runtime paths remain able to execute `app2unit`, CLI helpers, and user application packages.
- Steam remains enabled in the generated `axiom` config and is available through the user/system package closure.
- Repository validation proves the intended PATH/session shape with targeted evals and a full `axiom` toplevel build or records a precise build blocker.
- Deployment follow-up records live checks for desktop-launched Foot and Steam because this environment cannot prove the physical GUI session.

## Scope
- Update NixOS/Home Manager/Hyprland/UWSM/Caelestia session environment wiring only as needed to provide a correct command `PATH` to GUI-launched terminals and app launchers.
- Validate the Steam generated configuration and launcher availability as part of the same desktop environment fix.
- Add Legion design, verification, review, walkthrough, and wiki evidence required by the workflow.

## Non-goals
- Do not redesign the Axiom desktop shell, replace Caelestia, or revert to legacy end4/Quickshell launch paths.
- Do not debug individual Steam game/Proton failures, GPU driver behavior, or Steam account/runtime state unless PATH restoration proves unrelated.
- Do not change SSH login shell behavior, user identity, SSH tunnel settings, or remote host configuration.
- Do not introduce Darwin desktop/system changes.

## Assumptions
- `git` and `awk` are already present in evaluated system/user package closures or base system paths; the failure is from GUI session path propagation.
- SSH login works because login shells receive a fuller environment than the graphical session startup path.
- Steam launch failure may share the same root cause until live checks or logs prove otherwise.
- The fix should be declarative and owned by the dotfiles, not by mutable per-user shell startup edits.

## Constraints
- Follow Legion workflow and the git-worktree PR envelope for repository modifications.
- Keep changes minimal and focused on session environment propagation.
- Preserve existing Hyprland/UWSM `start-hyprland` launcher behavior, `hyprland-session.target` ownership, and Caelestia duplicate-instance protection.
- Prefer generated/evaluable session data over assumptions from the interactive shell environment.

## Risks
- Nix eval/build can prove generated configuration, but cannot prove physical GUI launch behavior from this container/session.
- Over-broad PATH injection could mask missing package ownership or diverge from NixOS defaults.
- Steam may still fail after PATH is fixed if it has a separate graphics/runtime problem; that should become a follow-up with logs rather than silently expanding this task.

## Design Summary
Treat the Foot and likely Steam symptoms as a broken desktop session environment. The recommended direction is to make the graphical session export a deterministic command `PATH` that includes system profile, user profile, local bin, and relevant NixOS-provided package paths before Hyprland-spawned programs, UWSM apps, Caelestia launcher children, and systemd-user services execute helpers. Verification should inspect generated NixOS/Home Manager/session data and ensure Steam remains in the generated closure, then leave physical Foot/Steam smoke tests as deployment checks.

## Phases
1. Materialize this task contract.
2. Write and review a short RFC because this touches session startup and application launch environment.
3. Implement the minimal declarative session environment fix inside a Legion worktree/PR envelope.
4. Verify with targeted evals plus an `axiom` system build where feasible.
5. Run change review, walkthrough, wiki writeback, and PR lifecycle cleanup.
