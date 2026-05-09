# Patterns

## Git Flake Validation With New Modules

When validating a Git-backed flake after adding new module files, mark those files as tracked or intent-to-add before running `nix eval`/`nix build`. Otherwise Nix may evaluate the Git source without untracked module files, and `_module.check = false` can hide missing option declarations.

Recommended pre-validation command shape:

```sh
git add -N <new-module-files>
```

The final commit must still add the files normally.

When validating an impure flake from a nested PR worktree, set `DOTFILES_HOME` to the worktree path and prefer a `path:` flake reference to that worktree. A stale ambient `DOTFILES_HOME` can cause generated Home Manager sources to point at an older Nix store snapshot even when the command is run from the intended worktree.

## Runtime Entry Validation

For display-manager runtime regressions, validate the effective NixOS session data rather than guessing desktop entry names. Check `services.displayManager.sessionData.sessionNames`, the generated `share/wayland-sessions/*.desktop` entries, and the consumer command that references them.

For NetworkManager/iwd changes, validate service ownership explicitly: NetworkManager backend/DNS, iwd `EnableNetworkConfiguration`, resolved enablement, legacy DHCP service presence, and any generated NetworkManager ensure profiles.

For Hyprland config syntax migrations, do not rely on Nix build/eval alone. Build a combined config from generated pre config, checked-in base config, and generated post/theme config, then run the evaluated Hyprland binary with `--verify-config`.

For visible-shell startup regressions where Hyprland shows a cursor but the desktop stays black, validate the generated startup chain directly. Check that `exec-once = hey hook startup` is present, startup hooks are ordered as expected, the early session hook starts `hyprland-session.target`, DMS/Quickshell is wanted by the session target, wallpaper starts through the configured background hook, and no foreground lock command gates the shell path.

For Hyprland/UWSM startup warnings, validate the actual command resolution instead of only checking desktop entry existence. A `uwsm start` dry run should resolve to `start-hyprland`; if it resolves to direct `Hyprland`, the generated startup path can still trigger the upstream warning even when UWSM is present.

For autossh reverse tunnel regressions, validate both sides of the generated shape: the remote-forward string must remain loopback-only and port-unique, and the local target service must exist as an active daemon if the tunnel forwards to `127.0.0.1:22`.

## 上游桌面参考采用模式

使用大型外部桌面 dotfiles 仓库作为产品灵感时，应先提取能力，再考虑代码移动。需要把 compositor/session model、shell ownership、notification/search/control surfaces、theming、state writes、dependency assumptions 和 rollback boundaries 与 Axiom 当前 Nix-native model 对比。

不要导入 mutable installers、distro package-manager logic、generated user state，或与 Axiom UWSM/systemd ownership 冲突的 session assumptions。优先采用分阶段本地能力等价；在 shell-native replacements 验证前，保留外部工具作为 fallback。

## Quickshell Notification Center Pattern

For Axiom notification UI, keep `NotificationServer` as the ingress and use `trackedNotifications` as the runtime source of truth. Keep notification history session-local unless a task explicitly defines retention, clear behavior, disable switches, and privacy handling.

When validating new Quickshell QML files from a Git-backed flake, stage or intent-to-add the new files before `nix eval`/`nix build`, then pair Nix build evidence with a real-session test plan. Headless/offscreen Quickshell can fail at `No PanelWindow backend loaded`; treat that as an environment limitation, not a substitute for Hyprland layer-shell testing.

Keep Quickshell `Variants` composition simple: use one per-screen `PanelWindow` delegate per `Variants` block. If multiple windows need the same screen model, create separate `Variants` blocks or an explicit wrapper component; do not add sibling `PanelWindow` delegates in one `Variants` block.

## Quickshell Search and Actions Pattern

For Axiom shell-owned search/actions, keep the visible UI in Quickshell and keep provider execution behind fixed local verbs. QML may compose results and invoke reviewed argv arrays or repository-owned helper subcommands, but it should not parse desktop-entry `Exec` strings into shell commands or pass user query text to `sh -lc`.

Search providers should be independently bounded: app launch validates desktop IDs against scanned entries, calculator input is parsed as data through a restricted expression evaluator or equivalent local backend, emoji data stays local/offline, web search only opens an encoded user-requested URL, and clipboard history has explicit caps, clear, disable, and rollback behavior.

Fallback-first rollout remains required for launcher replacements. Keep Fuzzel available through a direct action and binding until the Quickshell search panel, IPC/focus behavior, and real app/clipboard actions are verified in an Axiom Wayland session.

When verifying Quickshell search changes headlessly, treat Nix eval/build, helper smoke tests, scope grep, `git diff --check`, and `Hyprland --verify-config` as useful evidence, but record that `PanelWindow` runtime behavior still requires a real layer-shell session.
