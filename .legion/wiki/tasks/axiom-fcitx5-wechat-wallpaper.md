# Axiom Fcitx5 WeChat Input And Wallpaper

Status: local implementation verified with follow-up runtime fixes; PR lifecycle in progress
Task: `.legion/tasks/axiom-fcitx5-wechat-wallpaper/`
Branch: `legion/axiom-fcitx5-wechat-wallpaper-input-wallpaper`
Worktree: `.worktrees/axiom-fcitx5-wechat-wallpaper`
PR: https://github.com/Thrimbda/dotfiles/pull/12

## Summary

Added a reusable Fcitx5 input module and enabled it on `axiom` with Catppuccin Mocha, Rime, Fcitx5 Chinese addons, and GTK/Qt frontends for desktop app input support.

Follow-up fixes addressed reported runtime issues where the Quickshell dock buttons did not respond and the wallpaper appeared small/centered.

## Effective Outcome

- New reusable option root: `modules.desktop.input.fcitx5`.
- `fcitx5-rime.enable` now delegates to the reusable module for existing hosts.
- `axiom` Fcitx5 addons evaluate to `fcitx5-gtk`, `fcitx5-qt6`, `fcitx5-rime`, `fcitx5-chinese-addons`, and `catppuccin-fcitx5`.
- `axiom` Fcitx5 classic UI theme evaluates to `catppuccin-mocha-mauve`.
- `axiom` wallpaper evaluates to `/home/c1/the-great-sage.jpg` with `stretch` mode.
- `quickshell.service` is wanted/after/part-of `hyprland-session.target` only, so it starts after the Hyprland environment import path.
- Wallpaper startup kills stale `swaybg` before launching the configured stretched wallpaper.

## Validation

Focused git-flake evaluation passed for `axiom` input settings, wallpaper settings, Quickshell service target wiring, generated wallpaper hook shape, existing `atlas` compatibility, and `axiom` system toplevel derivation.

## Notes

- No Linux package for official Tencent WeChat Input Method was found in pinned nixpkgs, unstable, or fetched `z.weixin.qq.com` assets. The implemented path configures Fcitx5 Chinese input support suitable for WeChat rather than packaging official WeType for Linux.
- Runtime typing inside WeChat and Quickshell button clicks still need validation after applying the `axiom` rebuild.
