# Dotfiles Fcitx5 Wayland GTK IM Module

## Goal
Remove the Fcitx5 Wayland diagnostic warning caused by exporting `GTK_IM_MODULE` when the Wayland input method frontend is enabled and usable.

## Problem
The desktop input method module can enable Fcitx5's Wayland frontend, but the session still risks carrying legacy GTK input method environment variables. On Wayland, Fcitx5 recommends not setting `GTK_IM_MODULE` when the native Wayland frontend works, because GTK should use the Wayland text-input path rather than the legacy IM module path.

## Acceptance
- Wayland hosts using `modules.desktop.input.fcitx5.waylandFrontend = true` do not export `GTK_IM_MODULE` through the managed desktop session environment.
- The Fcitx5 module exposes a reusable policy for Wayland GTK IM handling instead of hardcoding an Axiom-only workaround.
- Existing Fcitx5 addon behavior for GTK/Qt/Rime/Pinyin remains unchanged.
- Non-Wayland or non-Fcitx configurations are not broadened by this task.
- Focused Nix evaluation or an equivalent syntax/config validation succeeds, or any blocker is documented with evidence.

## Scope
- Update the reusable Fcitx5/Wayland desktop module wiring in Nix.
- Prefer module-level environment policy over host-local shell edits.
- Update `axiom` only if needed to opt into the reusable Wayland frontend policy.
- Add task-local Legion implementation, verification, review, walkthrough, and wiki evidence.

## Non-goals
- Do not replace Fcitx5, Rime, or Chinese addon configuration.
- Do not remove GTK Fcitx5 addon packages; GTK applications may still need packaged support outside the environment variable warning path.
- Do not tune Qt input method variables unless evidence shows the same Wayland frontend warning applies.
- Do not perform live desktop-session validation beyond static evaluation in this task.

## Assumptions
- The reported warning comes from Fcitx5 diagnostics in the Axiom Hyprland Wayland session.
- `waylandFrontend = true` is the correct NixOS/Fcitx5 switch for using the native Wayland frontend.
- Unsetting `GTK_IM_MODULE` is preferable to setting it to an empty string if the managed session environment supports omission.

## Constraints
- Keep the change minimal and reusable.
- Preserve existing host input method features unless directly related to the warning.
- Avoid adding backward compatibility paths without a concrete persisted-data or external-consumer need.

## Risks
- Some legacy GTK applications may rely on `GTK_IM_MODULE=fcitx`; this task intentionally follows the Wayland recommendation when the native frontend is enabled.
- Static Nix validation cannot prove live GTK text input behavior in every application.
- Environment variables may also be injected outside this repository; such external sources are out of scope unless discovered in managed files.

## Design Summary
Make Wayland-native Fcitx5 the explicit module policy: hosts that enable the Fcitx5 Wayland frontend should avoid exporting `GTK_IM_MODULE` from the managed Wayland session. Keep addon installation unchanged so GTK/Qt support remains available while the session environment no longer forces GTK onto the legacy IM module path.

## Phases
1. Identify managed environment sources for input method variables.
2. Implement the reusable Fcitx5 Wayland GTK IM policy and host opt-in if needed.
3. Run focused Nix/config validation.
4. Record verification, review, walkthrough, and wiki evidence.
5. Complete the PR-backed worktree lifecycle.
