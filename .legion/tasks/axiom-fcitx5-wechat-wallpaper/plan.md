# Axiom Fcitx5 WeChat Input And Wallpaper

## Goal
Make the Fcitx5 desktop input setup reusable across hosts, enable it on `axiom` with Catppuccin Mocha styling and Chinese input suitable for WeChat, and set `axiom`'s wallpaper to `/home/c1/the-great-sage.jpg`.

## Problem
`axiom` currently enables the narrow `fcitx5-rime` module. That works for Rime but does not provide a reusable Fcitx5 baseline for themed input, additional Chinese engines, or WeChat-oriented desktop input support. The host also still uses the theme default wallpaper rather than the requested local image.

## Acceptance
- A reusable `modules.desktop.input.fcitx5` module exists for Linux desktop hosts.
- The reusable module enables Fcitx5 through current NixOS input method options, supports Rime, supports Fcitx5 Chinese addons, and applies a Catppuccin Fcitx5 theme.
- Existing `modules.desktop.input.fcitx5-rime.enable` consumers continue to evaluate by delegating to the reusable Fcitx5 module.
- `axiom` enables the reusable Fcitx5 module with Rime, Chinese addons, and Catppuccin Mocha.
- `axiom` sets the wallpaper path to `/home/c1/the-great-sage.jpg` and stretches it instead of leaving it centered.
- `axiom` Quickshell starts from the Hyprland session target after compositor environment import so dock buttons can use Hyprland IPC and launch GUI apps.
- Focused Nix evaluation for `axiom` succeeds, or blockers are documented with evidence.

## Scope
- Add or update NixOS modules under `modules/desktop/input`.
- Update `hosts/axiom/default.nix` for input method and wallpaper wiring.
- Update the existing Hyprland/Quickshell runtime hooks only as needed to fix the reported `axiom` sidebar and wallpaper behavior.
- Add task-local Legion evidence for implementation, verification, and handoff.

## Non-goals
- Do not package a new official WeChat Input Method binary without a stable Linux download URL and license/source contract.
- Do not change unrelated host wallpapers.
- Do not replace the active global desktop theme.
- Do not redesign the Quickshell dock UI.
- Do not alter user dictionaries or private Fcitx/Rime data.

## Assumptions
- Catppuccin Mocha uses the `catppuccin-mocha-mauve` Fcitx5 theme variant unless a different accent is requested later.
- `/home/c1/the-great-sage.jpg` is the requested wallpaper asset.
- Current upstream/nixpkgs do not expose an official Linux WeChat Input Method package; configuring Fcitx5 Rime/Pinyin support is the credible Linux path for Chinese input in WeChat.

## Constraints
- Work must happen in `.worktrees/axiom-fcitx5-wechat-wallpaper` on branch `legion/axiom-fcitx5-wechat-wallpaper-input-wallpaper`.
- Base ref is `origin/master`.
- Keep the change minimal and host-scoped where possible.

## Risks
- If Tencent later publishes an official Linux WeType package, this task will not install it automatically.
- Fcitx5 runtime behavior inside WeChat still depends on the actual WeChat client frontend and compositor session.
- Quickshell click behavior still needs live session confirmation after rebuild because static evaluation can only validate systemd wiring and config shape.
- The wallpaper path is outside the Nix store, so evaluation can validate the path string but not enforce content availability on every rebuild target.

## Design Summary
Introduce a generic `fcitx5` input module with small options for Rime, Fcitx5 Chinese addons, extra addons, and Catppuccin theme flavor/accent. Keep the old `fcitx5-rime` option as a compatibility delegate for existing host configs. Update `axiom` to use the generic module with Catppuccin Mocha and set the theme wallpaper override to the requested home-directory image.

## Phases
1. Add reusable Fcitx5 module and delegate old Rime-only option.
2. Wire `axiom` to the reusable module and wallpaper path.
3. Evaluate focused `axiom` attributes.
4. Record verification, review, walkthrough, and wiki evidence.
5. Complete the PR-backed worktree lifecycle.
