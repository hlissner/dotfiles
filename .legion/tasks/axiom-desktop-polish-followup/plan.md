# Axiom Desktop Polish Followup

## 目标

Resolve three remaining Axiom desktop regressions after the Caelestia migration: Steam should render crisply on the 4K fractional-scale desktop, Caelestia shortcut bindings should trigger the registered shell actions, and opencode should be available from the default Axiom command path.

## 问题陈述

Axiom now boots into the Caelestia/Hyprland desktop, but post-deploy polish issues remain. Steam is visibly low-resolution or jagged on the 3840x2160@60 display with scale 1.5, consistent with XWayland fractional-scaling and Steam HiDPI handling. Caelestia shortcut bindings are generated, but the live session reports that they do not work, so the generated Hyprland mapping and shell global-shortcut registration need to be aligned with the upstream Caelestia model. The host also adds $HOME/.opencode/bin through environment.variables.PATH, but opencode is still not in the default path, so shell and desktop session path ownership need to be made explicit.

## 验收标准

- [ ] Axiom-generated Hyprland config includes the intended XWayland HiDPI behavior for fractional-scale displays, and Steam receives an explicit desktop UI scale matching the active monitor scale.
- [ ] Steam remains enabled and available in the generated Axiom system package closure; the fix does not expand into individual game, Proton, or GPU runtime debugging.
- [ ] Generated Caelestia keybinds use valid Hyprland syntax and map only to shortcut names or CLI commands supported by the current Caelestia shell package.
- [ ] Caelestia launcher/sidebar/session/media/brightness/screenshot and other retained bindings remain represented in generated keybind text or are deliberately routed to supported CLI commands.
- [ ] opencode is resolvable from Axiom interactive zsh sessions and from the generated desktop/UWSM session PATH without relying on literal unexpanded PATH strings.
- [ ] Targeted Nix evaluation validates the generated Steam scale, Hyprland keybind/session PATH shape, and opencode path integration.
- [ ] Hyprland parser validation and an Axiom toplevel build pass, or any blocker is recorded with the strongest available focused evidence.
- [ ] Legion verification, readiness review, walkthrough, wiki closeout, and PR lifecycle evidence are recorded.

## 假设 / 约束 / 风险

- **假设**: The Steam visual issue is caused by Axiom 4K fractional scaling and XWayland/Steam HiDPI behavior, not by a specific game engine or Proton title.
- **假设**: The Caelestia shell package currently registers global shortcuts through appid caelestia and the generated Hyprland config should target that supported action set.
- **假设**: opencode is installed out of band under the user-owned $HOME/.opencode/bin directory, so this task should expose that existing directory rather than package opencode in Nix.
- **假设**: Live GUI smoke tests are still deployment checks because this environment cannot prove physical Steam rendering or shortcut dispatch.
- **约束**: Follow Legion workflow and the git-worktree PR envelope for repository modifications.
- **约束**: Keep changes minimal and focused on Axiom desktop polish regressions.
- **约束**: Do not restore end4, legacy Quickshell, fuzzel fallback, or unmanaged Caelestia shell launch paths.
- **约束**: Do not change unrelated Darwin opencode handling.
- **约束**: Keep Steam runtime and game-specific debugging out of scope unless the focused desktop-scale fix proves unrelated.
- **风险**: Hyprland force-zero-scaling changes XWayland behavior globally for the Hyprland session and can make non-HiDPI X11 apps appear smaller if they do not self-scale.
- **风险**: Steam HiDPI environment variables can improve the client UI but cannot guarantee every game selects native resolution.
- **风险**: Caelestia global shortcuts can be statically aligned with upstream names, but live DBus/portal dispatch still needs a real Hyprland session for final confirmation.
- **风险**: PATH fixes that rely on mutable $HOME/.opencode/bin cannot prove the binary exists unless the live host has opencode installed.

## 要点

- Steam symptom is handled first as fractional-scale XWayland/HiDPI integration, not as a per-game or Proton runtime failure.
- Caelestia keybinds must be aligned with the shortcut names registered by the current upstream shell package and validated through generated Hyprland config.
- opencode PATH ownership must be explicit for both interactive zsh and the UWSM/Hyprland desktop session; literal `$PATH` strings in `environment.variables` are not sufficient evidence.
- Local validation can prove generated config and build shape, but live Steam rendering and shortcut dispatch remain Axiom deployment smoke checks.

## 范围

- Update Axiom/Hyprland declarative config for XWayland HiDPI and generated session PATH where needed.
- Update the Steam module or Axiom host config so Steam receives an explicit desktop UI scale on fractional-scale Hyprland displays.
- Update generated Caelestia keybinds so they align with current upstream shortcut names and supported CLI routes.
- Replace or augment the ineffective Axiom opencode PATH wiring with explicit shell and desktop session path ownership.
- Add task-local validation, review, walkthrough, and wiki evidence.

## 非目标 / Out of Scope

- Do not debug individual Steam games, Proton prefixes, account state, or GPU driver internals.
- Do not redesign the entire Axiom keymap or Caelestia product integration.
- Do not package opencode in Nix or move the user-owned installation directory.
- Do not change SSH, autossh, wallpaper, icon-theme, or unrelated desktop behavior.
- Do not perform live graphical validation unless a live Axiom Hyprland session is available.

## 设计索引 (Design Index)

> **Design Source of Truth**: `docs/rfc.md` (reviewed in `docs/review-rfc.md`, PASS)

**摘要**:
- Treat Steam as a fractional-scale XWayland/HiDPI integration issue first: make Hyprland avoid compositor-side low-resolution XWayland scaling and pass Steam an explicit desktop UI scaling factor derived from the active monitor scale.
- Treat Caelestia shortcuts as a generated mapping issue: compare the generated config against the current Caelestia shell shortcut registrations and only keep global dispatcher names that exist in the package; use supported CLI commands for actions that are not global shortcuts.
- Treat opencode as a path ownership issue: remove reliance on unexpanded environment.variables.PATH and explicitly prepend the user opencode bin directory in zsh startup plus the generated UWSM desktop session PATH.
- Verify statically with Nix evals for rendered config and package closure, then run Hyprland config parser validation and the Axiom toplevel build as the strongest local evidence.

## 阶段概览

1. **Brainstorm** - Materialize stable contract for the three Axiom polish regressions
2. **Design Gate** - Write and review a short RFC for Steam HiDPI, Caelestia shortcut mapping, and opencode PATH ownership
3. **Engineer** - Implement minimal declarative fixes in an isolated worktree
4. **Verify Change** - Run focused static validation plus parser/build checks
5. **Review Change** - Assess readiness, scope, and security-sensitive surfaces
6. **Report Walkthrough** - Generate reviewer-facing summary and PR body
7. **Legion Wiki** - Write reusable closeout decisions and maintenance notes

---

*创建于: 2026-05-10 | 最后更新: 2026-05-10*
