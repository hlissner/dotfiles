# Axiom Caelestia README Alignment

## Task Identity

- Name: Axiom Caelestia README Alignment
- Task ID: `axiom-caelestia-readme-alignment`
- Trigger: user requested Caelestia README-aligned finder/explorer, font, rounded-window, and `qtengine` configuration fixes for Axiom.

## 目标

Align Axiom Caelestia desktop configuration with upstream Caelestia README defaults and the requested font, file manager, rounded-window, and Qt platform-theme behavior.

## 问题陈述

The current local Caelestia integration only writes minimal shell settings and still carries prior qt6ct workaround values. It does not encode the README font family defaults, does not install or declare the requested Chinese and terminal font fallbacks, and its Hyprland styling/env differs from the Caelestia dots guidance for qtengine and rounded windows. The user also wants a Finder-like file manager path wired through Caelestia.

## 验收标准

- [ ] Caelestia shell settings include the README font family values: clock Rubik, material Material Symbols Rounded, mono CaskaydiaCove NF, sans Rubik.
- [ ] Font packages and fontconfig defaults cover Rubik, Material Symbols, Caskaydia Cove Nerd Font, LXGW Neo Xihei, Sarasa Mono SC, Noto Sans CJK SC, and a FiraCode Nerd Font Mono terminal face.
- [ ] Foot uses the requested terminal font family without changing the default terminal command.
- [ ] Caelestia default app settings and Hyprland file explorer binding use Thunar as the Finder-like explorer, matching the README example and the host-enabled desktop app.
- [ ] Repo-owned Hyprland, UWSM, session, and Caelestia service environments use QT_QPA_PLATFORMTHEME=qtengine where Caelestia is enabled, and include the README Qt Wayland decoration env needed for app-side decorations.
- [ ] Application windows use Caelestia-style rounded Hyprland decoration values rather than the previous square-looking local styling.
- [ ] No legacy end4/fuzzel path is reintroduced, Darwin remains isolated, and existing Caelestia wallpaper ownership remains intact.
- [ ] Static Nix validation or the strongest available focused equivalent proves generated settings/env/font changes.

## 假设 / 约束 / 风险

- **假设**: Caelestia does not ship a macOS Finder clone; the README example treats thunar as the explorer app, and Axiom already enables Thunar.
- **假设**: The user wants the upstream Caelestia dots README qtengine value to replace the prior qt6ct workaround despite earlier local issue notes.
- **假设**: A Nix package or local fallback is available for qtengine; if not, implementation records the strongest viable package/env fallback without changing the requested env value.
- **假设**: FiraCode Nerd Font Mono is the practical Nix/fontconfig family for the requested terminal Firacode NF Mono.
- **假设**: Live graphical validation may require deploying and restarting Hyprland outside this automation session.
- **假设**: Axiom is being configured as a new Caelestia machine, so implementation should prefer the clean upstream-aligned setup over compatibility with old session workarounds.
- **约束**: Keep changes focused on Axiom/Caelestia desktop configuration.
- **约束**: Do not import the entire upstream Caelestia Home Manager module or replace this repository-owned integration boundary unless required.
- **约束**: Do not copy the full README example shell.json; only encode intentional overrides because the README warns against copying all options.
- **约束**: Do not change wallpaper ownership or host wallpaper source.
- **约束**: Do not touch unrelated SSH, network, boot, or non-Axiom desktop behavior.
- **约束**: Do not carry compatibility shims or dual configuration paths for the previous Axiom desktop state.
- **风险**: qtengine may not exist in nixpkgs under the same Arch/AUR package name, so package support needs verification.
- **风险**: Font family names can differ from package names; static config validation cannot prove rendered glyph fallback without a live session.
- **风险**: Rounded-window appearance is partly compositor and partly toolkit behavior, so a Hyprland restart and app relaunch may be required to confirm visually.
- **风险**: Replacing qt6ct with qtengine may re-open the old launcher icon-block workaround if upstream behavior differs on this system.

## 要点

- Use upstream Caelestia README examples as configuration evidence, especially `appearance.font.family`, `general.apps.explorer = ["thunar"]`, and the main dots `QT_QPA_PLATFORMTHEME=qtengine` Hyprland env.
- Keep the local Nix integration minimal and repo-owned; do not copy the entire README example `shell.json` because upstream explicitly says the example is reference material, not a recommended full config.
- Treat Thunar as the Finder-like explorer path because Caelestia's README example and meta package optional dependency both point to `thunar`.
- Configure font fallback in the theme/fontconfig layer, then expose the requested Caelestia font family names in shell settings.
- Align compositor decoration values with Caelestia dots-style rounded application windows, while noting that live visual proof still needs app relaunch or Hyprland restart.

## 范围

- modules/desktop/caelestia.nix
- modules/desktop/hyprland.nix
- modules/themes/default.nix
- modules/themes/autumnal/default.nix
- modules/themes/autumnal/hyprland.nix
- modules/desktop/term/foot.nix or foot config generation

## Non-Goals

- Do not change Caelestia upstream source code.
- Do not redesign the whole desktop theme or keybind scheme.
- Do not migrate to Nautilus, Dolphin, Nemo, or another file manager unless Thunar proves impossible.
- Do not add live-session-only assertions as blocking static acceptance.
- Do not complete unrelated pending Caelestia PR lifecycle tasks.

## 设计索引 (Design Index)

> **Design Source of Truth**: （暂无）

**摘要**:
- Use the upstream README as the source for Caelestia shell settings, but keep a minimal shell.json override rather than copying the entire example.
- Use Thunar as the Finder-like explorer because upstream README examples and meta package optdepends identify it as the expected file manager path.
- Move font policy into the theme/fontconfig layer and only add Caelestia-specific font family settings to shell.json.
- Set qtengine consistently across repo-owned Caelestia/Hyprland/UWSM environments to satisfy the README-alignment request.
- Align Hyprland decoration defaults with upstream Caelestia dots values for rounded application windows.

## 阶段概览

1. **Brainstorm** - Materialize stable task contract from the user request and upstream README evidence.
2. **Engineer** - Patch Caelestia settings, fonts, Qt env, explorer defaults, and rounded-window styling in an isolated worktree.
3. **Verify Change** - Run focused Nix evaluation/build validation for generated Axiom settings and packages.
4. **Review Change** - Assess readiness, scope control, and regression risk.
5. **Report Walkthrough** - Generate reviewer-facing summary and PR body.
6. **Legion Wiki** - Write reusable Caelestia configuration decisions to the wiki layer.

---

*创建于: 2026-05-10 | 最后更新: 2026-05-10*
