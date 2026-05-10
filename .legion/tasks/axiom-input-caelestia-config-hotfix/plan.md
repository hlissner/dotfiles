# Axiom Input And Caelestia Config Hotfix

## Task Identity

- Name: Axiom Input And Caelestia Config Hotfix
- Task ID: `axiom-input-caelestia-config-hotfix`
- Trigger: user reported that after boot Caelestia shows `keyboard layout changed to: unknown`, the Super key is not recognized, and the Caelestia `shell.json` is read-only.
- Risk: low

## 目标

Restore reliable Axiom Hyprland Super-key shortcuts after boot and make the local Caelestia `shell.json` editable while preserving a repo-owned default seed.

## 问题陈述

Axiom currently generates Hyprland input/keybind config and a minimal Caelestia `shell.json` through Nix. The generated keybinds use non-canonical mixed-case modifier names, which is a weak point when debugging a live Super-key regression on current Hyprland. The generated Caelestia `shell.json` is written by Home Manager as a Nix store-backed file, so users cannot edit it from the live Caelestia settings flow or a normal editor.

The keyboard layout toast should not be treated as an upstream source rewrite task. It is sufficient for this hotfix to stop repo defaults from creating noisy or misleading layout-change toasts while keeping the underlying Axiom keyboard facts in generated Hyprland config.

## 验收标准

- [ ] Generated Hyprland keybinds use canonical uppercase modifier names such as `SUPER`, `CTRL`, `ALT`, and `SHIFT` for Super-key bindings.
- [ ] Generated Hyprland input config still declares the Axiom keyboard layout and Colemak variant from Nix-owned host facts.
- [ ] Repo-owned Caelestia defaults disable the keyboard-layout-changed toast so boot-time `Unknown` layout notifications are not shown by default.
- [ ] `~/.config/caelestia/shell.json` is seeded as a normal writable user file when missing or when the previous generation left a Nix-store symlink.
- [ ] Existing real user edits to `~/.config/caelestia/shell.json` are not overwritten by service restarts or future rebuilds.
- [ ] The fix stays within Axiom/Hyprland/Caelestia integration and does not reintroduce end4, fuzzel, top-level `catchall`, or direct unmanaged shell process starts.
- [ ] Focused Nix evaluation and Hyprland parser validation prove the generated config shape; live session smoke remains a post-deploy check if unavailable here.

## 假设 / 约束 / 风险

- **假设**: The reported host is Axiom, because the active Caelestia/Hyprland integration and prior Legion decisions are Axiom-scoped.
- **假设**: The Super-key regression is best addressed first by canonicalizing generated Hyprland modifier tokens, not by changing the user's physical keyboard layout or replacing the input stack.
- **假设**: The user wants `shell.json` to be locally editable after Nix deployment; Nix should seed defaults but should not continuously own the file contents.
- **约束**: Keep Axiom keyboard facts Nix-owned through generated Hyprland config.
- **约束**: Do not modify upstream Caelestia source or copy the full upstream example `shell.json`.
- **约束**: Do not overwrite a real existing user-owned `shell.json`.
- **约束**: Do not change wallpaper ownership, Caelestia service ownership, or unrelated desktop applications.
- **风险**: Static validation cannot prove the physical Super key is recognized without a live Hyprland session after deployment.
- **风险**: Disabling the keyboard layout toast hides only that notification; if Hyprland still reports an unknown active keymap in live `hyprctl devices`, a separate upstream/runtime task may be needed.

## 要点

- Treat this as a low-risk generated-config hotfix rather than a shell migration.
- Use canonical Hyprland modifier spelling to remove ambiguity from Super-key bindings.
- Keep the existing minimal Caelestia settings as seed data, but move `shell.json` out of Home Manager's immutable file ownership.
- Seed the mutable `shell.json` from the Caelestia user service before startup, replacing only missing files or old symlinks.

## 范围

- `modules/desktop/hyprland.nix`
- `modules/desktop/caelestia.nix`
- `.legion/tasks/axiom-input-caelestia-config-hotfix/**`
- `.legion/wiki/**` closing writeback after validation/review

## Non-Goals

- Do not debug physical keyboard firmware or hardware remapping in this task.
- Do not switch away from Colemak or Fcitx5.
- Do not change global shortcut DBus plumbing or restore previous broken `global, caelestia:*` dispatch.
- Do not turn the mutable `shell.json` into an exhaustive repo-owned upstream config copy.
- Do not claim live Super-key behavior is fully proven without a deployed Hyprland session.

## Design Index

> **Design Source of Truth**: Design-lite contract in this `plan.md`; no separate RFC required for the low-risk scoped hotfix.

**Design Summary**:
- Canonicalize generated Hyprland modifier names in keybind text.
- Add an intentional Caelestia default to suppress keyboard-layout toasts that show `Unknown` during boot/device refresh.
- Replace immutable Home Manager ownership of `caelestia/shell.json` with a service pre-start seed script that creates a writable file only when needed.
- Preserve existing service ownership, CLI IPC keybind routes, wallpaper seed behavior, and minimal shell settings policy.

## 阶段概览

1. **Brainstorm** - Materialize the scoped hotfix contract.
2. **Engineer** - Patch generated Hyprland keybinds and mutable Caelestia shell config seeding in the isolated worktree.
3. **Verify Change** - Run focused Nix evals, generated Hyprland parser validation, and the strongest available build/static checks.
4. **Review Change** - Assess readiness, scope control, safety around user-owned mutable config, and residual live-session risk.
5. **Report Walkthrough** - Generate reviewer-facing summary and PR body.
6. **Legion Wiki** - Update current decisions/patterns/maintenance for mutable Caelestia config and canonical Hyprland modifiers.

---

*Created: 2026-05-10 | Last updated: 2026-05-10*
