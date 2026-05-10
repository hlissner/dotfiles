# RFC: Axiom Desktop Polish Followup

## Status

- Task: `axiom-desktop-polish-followup`
- Profile: standard RFC
- Decision: proposed
- Scope: Steam HiDPI rendering, Caelestia keybind dispatch, Axiom opencode PATH

## Context

Axiom is now on the Caelestia/Hyprland desktop stack. Three follow-up issues remain:

- Steam renders as visibly low-resolution or jagged on the `3840x2160@60` monitor with Hyprland scale `1.5`.
- Caelestia-related keybinds are generated in Hyprland config but do not work in the live session.
- `opencode` is installed under `$HOME/.opencode/bin`, but that directory is not present in the default Axiom command path.

Relevant current shape:

- `hosts/axiom/default.nix` sets the Axiom monitor to `3840x2160@60` and `scale = 1.5`.
- `modules/desktop/hyprland.nix` enables XWayland but does not currently force XWayland clients to self-scale.
- `modules/desktop/apps/steam.nix` wraps Steam only for fake-home and library fix behavior; it does not pass Steam an explicit desktop UI scale.
- `modules/desktop/hyprland.nix` generates Caelestia keybinds using Hyprland `global, caelestia:*` dispatchers.
- The current Caelestia package exposes both global shortcuts and IPC commands through `caelestia shell ...`.
- `hosts/axiom/default.nix` currently uses `environment.variables.PATH = "$HOME/.opencode/bin:$PATH"`, which is weak evidence for either login zsh or UWSM/Hyprland session PATH.

## Goals

- Make Steam render crisply in the Axiom 4K fractional-scale desktop path without debugging per-game runtime behavior.
- Make Axiom's Caelestia-related keyboard shortcuts trigger supported Caelestia actions reliably.
- Make `opencode` available in default Axiom interactive zsh and desktop-launched command environments.
- Keep changes declarative, minimal, and locally verifiable through generated config.

## Non-Goals

- No Proton prefix, individual game, account, or GPU driver debugging.
- No full keymap redesign or restoration of end4/legacy Quickshell/fuzzel behavior.
- No Nix packaging of opencode and no relocation of the existing user-owned install directory.
- No live GUI assertion unless an Axiom Hyprland session is available.

## Options

### Option A: Patch only Steam and leave Hyprland XWayland scaling alone

Set `STEAM_FORCE_DESKTOPUI_SCALING=1.5` for Axiom Steam, but leave compositor-side XWayland scaling unchanged.

Pros:

- Very small Steam-specific change.
- Avoids affecting other XWayland applications.

Cons:

- If the jagged output is from compositor-side XWayland upscaling, Steam can still render at the wrong pixel density.
- Does not address the known fractional-scale XWayland trade-off in the compositor.

### Option B: Force XWayland clients to self-scale and pass Steam an explicit UI scale

Enable Hyprland `xwayland.force_zero_scaling = true` and pass Steam a desktop scale derived from the configured Hyprland monitor scale.

Pros:

- Addresses the likely root: fractional-scale XWayland clients rendered low-res then scaled by the compositor.
- Steam gets a documented non-integer HiDPI knob while XWayland stops compositor-side pixel stretching.
- Static validation can prove both generated Hyprland config and Steam wrapper environment.

Cons:

- Other XWayland apps that do not self-scale may appear smaller.
- Steam games can still choose their own render resolution; live validation remains required.

### Option C: Route Caelestia keybinds through upstream-style global shortcuts

Keep `global, caelestia:*` dispatchers and adjust generated Hyprland syntax toward the upstream global-submap example.

Pros:

- Stays closest to upstream Caelestia keybind examples.
- Preserves shortcut names registered by the shell.

Cons:

- The live symptom is that global shortcut dispatch does not work, so this may preserve the broken integration surface.
- Reintroducing catchall behavior safely requires submap handling that previously caused parser problems when generated at top level.

### Option D: Route Caelestia keybinds through Caelestia CLI IPC

Change generated Hyprland bindings for Caelestia actions from `global, caelestia:*` to `exec, $caelestia shell ...` where a current IPC command exists. Keep direct CLI commands such as screenshot/record/clipboard/emoji where already appropriate.

Pros:

- Avoids dependence on DBus/global-shortcut dispatch for the reported broken key path.
- Uses the current upstream shell IPC surface, which is documented by `caelestia shell -s` and visible in the package source.
- Hyprland parser validation and generated-text checks can prove commands are present and avoid unsupported shortcut names.

Cons:

- Super-key press/release launcher semantics are less exact than the upstream global-shortcut plus interrupt model.
- IPC commands still require `caelestia-shell.service` to be running in the live session.

### Option E: Keep opencode in `environment.variables.PATH`

Leave the current host-level literal PATH string as-is.

Pros:

- No code change.

Cons:

- It has already failed the live acceptance signal.
- It does not explicitly participate in generated UWSM session PATH.
- It risks preserving literal `$HOME`/`$PATH` behavior rather than a resolved command path.

### Option F: Explicitly own opencode path in zsh and UWSM desktop session

Prepend `$HOME/.opencode/bin` in Axiom zsh startup and add the resolved Axiom home opencode directory to generated Hyprland/UWSM `desktopSessionPath`.

Pros:

- Covers both interactive shells and desktop-launched apps.
- Avoids relying on global literal PATH expansion.
- Does not package or move the user-owned opencode install.

Cons:

- Static validation can only prove the path is exported, not that the live host has the binary installed.

## Recommendation

Use Options B, D, and F.

- Steam: add Hyprland `xwayland.force_zero_scaling = true` only for scaled Hyprland monitor configs and pass Steam `STEAM_FORCE_DESKTOPUI_SCALING` from the generated monitor scale, defaulting to `1` on non-scaled hosts.
- Caelestia: route generated Caelestia action keybinds through supported `caelestia shell ...` IPC commands instead of Hyprland global-shortcut dispatchers for the broken live path.
- opencode: remove the ineffective Axiom `environment.variables.PATH` override and explicitly add `$HOME/.opencode/bin` to zsh startup plus the generated UWSM/Hyprland session PATH.

This is the smallest design that addresses all three reported symptoms at their likely integration boundaries while preserving previous decisions: no end4 fallback, no unmanaged shell process launches, and no Steam game-specific debugging.

## Detailed Design

### Steam / XWayland

- Add an `xwayland` block to generated Hyprland general config only when a configured monitor scale differs from `1`:

```conf
xwayland {
  force_zero_scaling = true
}
```

- In the Steam module, derive a Steam UI scale from `config.modules.desktop.hyprland.monitors`.
- Use the primary monitor when one is marked; otherwise use the first configured monitor.
- Default to `1` when no scale is configured.
- Wrap `steam` with `STEAM_FORCE_DESKTOPUI_SCALING=<scale>` while preserving existing fake-home and library-fix wrapper behavior.

### Caelestia Keybinds

Replace generated Hyprland global-dispatch keybinds with IPC-backed exec commands for the current Caelestia shell package:

- Launcher/sidebar/session drawers: `$caelestia shell drawers toggle <drawer>`.
- Brightness: `$caelestia shell brightness set +10%` and `$caelestia shell brightness set 10%-`.
- Media: `$caelestia shell mpris playPause`, `next`, `previous`, and `stop`.
- Screenshot picker: `$caelestia shell picker openFreeze` and `$caelestia shell picker open`.
- Keep existing direct CLI commands for full screenshot, recording, clipboard, and emoji where they already use supported Caelestia CLI commands.

Do not reintroduce top-level `catchall`. Do not add a new submap unless later live validation proves that Super-key press/release behavior is required and can be safely validated.

### opencode PATH

- Add `${config.home.dir}/.opencode/bin` to `desktopSessionPath` so generated `uwsm/env` exports it for the Hyprland/UWSM desktop session.
- Replace Axiom's host-level literal `environment.variables.PATH` with zsh `envInit` that prepends `$HOME/.opencode/bin` to `path` and deduplicates `PATH`.
- Keep Darwin hosts unchanged.

## Verification Plan

- Nix eval generated Axiom Hyprland keybinds and assert no `global, caelestia:` bindings remain for the converted actions.
- Nix eval generated keybinds and assert expected `caelestia shell drawers`, `mpris`, `brightness`, and `picker` commands are present.
- Nix eval generated `hypr/custom/general.conf` and assert `force_zero_scaling = true` is present.
- Nix eval generated Steam wrapper package or relevant derivation text to assert `STEAM_FORCE_DESKTOPUI_SCALING` is included.
- Nix eval generated `uwsm/env` and zsh env config to assert `.opencode/bin` is present.
- Assemble and run `Hyprland --verify-config` against the generated Axiom config when available.
- Run `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` or record a precise build blocker.

Live post-deploy checks:

- Rebuild/switch Axiom, restart the Hyprland session, launch Steam, and confirm the client is crisp at the 4K scale.
- Exercise Super Space/sidebar/session/media/brightness/screenshot bindings in the live session.
- Open a fresh Axiom shell and confirm `command -v opencode` resolves to `$HOME/.opencode/bin/opencode`.

## Rollback

- Steam/XWayland rollback: remove the generated `xwayland.force_zero_scaling` block and Steam scale wrapper addition.
- Caelestia rollback: restore the prior `global, caelestia:*` keybind mapping if live evidence shows IPC routing regresses behavior.
- opencode rollback: restore the previous Axiom PATH assignment, though that should only be done if the zsh/session path additions cause a concrete conflict.

Each rollback is independent; one area can be reverted without reverting the other two.

## Open Questions

- Live Axiom still needs to confirm whether Steam games themselves choose native render resolution after the client scaling fix.
- Super-key tap-to-launch behavior may need a follow-up if the explicit Super Space launcher shortcut is insufficient.
