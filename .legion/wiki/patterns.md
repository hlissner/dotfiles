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
