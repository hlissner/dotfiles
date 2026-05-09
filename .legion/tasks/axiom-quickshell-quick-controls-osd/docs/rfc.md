# RFC: Axiom Quickshell Quick Controls and OSD

> Status: draft for `review-rfc`
> Task: `.legion/tasks/axiom-quickshell-quick-controls-osd/`
> Contract: `.legion/tasks/axiom-quickshell-quick-controls-osd/plan.md`

## Context and evidence

- Parent Stage 3 requires quick controls for audio, network, Bluetooth, media, power/session, basic settings, plus Quickshell OSD while retaining external fallbacks: `.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md:120-137`.
- Task contract makes this Stage 3 only and keeps Stage 1 notifications / Stage 2 search as baseline: `.legion/tasks/axiom-quickshell-quick-controls-osd/plan.md:17-26`, `.legion/tasks/axiom-quickshell-quick-controls-osd/plan.md:30-40`.
- Current dock control entries still call external tools directly: `WIFI` -> `nm-connection-editor`, `BT` -> `blueman-manager`, `VOL` -> `pavucontrol`, `PWR` -> `wlogout`: `config/quickshell/axiom-shell/shell.qml:19-28`.
- Stage 2 established Quickshell-owned search, fixed helper verbs, IPC fallback to Fuzzel, and separate `Variants` / `PanelWindow` surfaces: `config/quickshell/axiom-shell/shell.qml:148-158`, `config/quickshell/axiom-shell/shell.qml:319-390`, `.legion/wiki/tasks/axiom-quickshell-search-actions.md:10-18`.
- Search helper pattern is a small fixed-verb CLI with JSON output and bounded local actions: `config/quickshell/axiom-shell/search/axiom-search-helper.py:1-23`, `config/quickshell/axiom-shell/SearchPanel.qml:85-106`.
- Quickshell package/service ownership is in Nix and bound to `hyprland-session.target`: `modules/desktop/quickshell.nix:35-66`.
- Current package set already includes fallback tools and `playerctl`: `modules/desktop/quickshell.nix:36-49`.
- Hyprland owns keybindings. Media/brightness keys currently invoke `hey .osd` for volume/brightness and direct `playerctl` for media: `config/hypr/hyprland.conf:313-328`.
- Existing `hey .osd` ends in `notify-send`, with volume and brightness subcommands mutating state through `pamixer` / `brightnessctl`: `config/hypr/bin/osd.zsh:19-40`, `config/hypr/bin/osd.d/volume.zsh:22-90`, `config/hypr/bin/osd.d/brightness.zsh:11-31`.

## Goals

- Make dock quick-control entries open a Quickshell-owned control panel/popover before external settings apps.
- Show useful status and common actions for audio, network, Bluetooth, media, session/power, and basic desktop settings/actions.
- Route volume, brightness, and media feedback to a Quickshell OSD while preserving current media keys and fallback command paths.
- Preserve Stage 1 notification center, Stage 2 search/actions, side dock, workspace buttons, clock, and Fuzzel/direct tool fallbacks.
- Keep implementation bounded, Nix-native, fixed-verb, and reviewable.

## Non-goals

- No Stage 4 dynamic wallpaper/theme pipeline, Matugen propagation, or lockscreen theme pipeline.
- No Stage 5 AI/cloud/OCR/translation/capture expansion.
- No full DBus control-center parity with GNOME/KDE settings apps in the first pass.
- No upstream shell framework import, installer scripts, generated mutable upstream state, or Rofi/DMS primary shell path.
- No changes to UWSM/greetd/Hyprland session ownership or Darwin boundaries.

## Options considered

### Option A: Keep external tools primary

Leave dock buttons and keybindings as direct `nm-connection-editor`, `blueman-manager`, `pavucontrol`, `wlogout`, `hey .osd`, and `playerctl` calls.

- Pros: lowest risk, known fallbacks stay intact.
- Cons: fails Stage 3 because Quickshell still does not own quick controls or OSD.

### Option B: Implement deep shell-native DBus managers now

Quickshell/QML directly manages NetworkManager, BlueZ, PipeWire/PulseAudio, MPRIS, power/session, and display settings.

- Pros: closest to a complete product desktop.
- Cons: large API surface, hard to validate headlessly, high risk of regressing existing external tools and keybindings.

### Option C: Quickshell UI + small fixed-verb control helper + external fallbacks

Quickshell owns visible panel and OSD; a repository-owned helper returns status snapshots and performs reviewed verbs; Nix owns packages/services; Hyprland only routes bindings/wrappers.

- Pros: matches Stage 2 safety pattern, gives visible product value, keeps fallbacks, and allows incremental DBus depth later.
- Cons: first pass status may be shallower than full settings apps, and live IPC/OSD behavior still needs session verification.

### Decision

Choose **Option C**. It satisfies Stage 3 without turning QML into an unbounded desktop-settings implementation and keeps rollback to current direct commands simple.

## Proposed design

### UI and composition

- Keep `shell.qml` as composition root; add focused components such as `QuickControlsPanel.qml`, `QuickControlSection.qml`, `OsdOverlay.qml`, and helper/model glue under `config/quickshell/axiom-shell/`.
- Add quick controls and OSD as separate `Variants { model: Quickshell.screens }` blocks with one `PanelWindow` per delegate, following the Stage 1/2 pattern.
- Replace dock `WIFI`, `BT`, `VOL`, and `PWR` primary behavior with `action: "quickControls"` plus an optional initial section. `APP` remains search. `SHOT`, `REC`, and `LOCK` may remain direct but should also appear in the panel as basic actions.
- Quick controls open next to the side dock. Opening quick controls closes search/notifications or at least avoids overlapping active panels; implementation should choose one simple policy and keep it consistent.
- The panel should refresh status on open and after actions. A manual refresh button is acceptable for the first pass; continuous polling is optional and should be low-frequency if used.

### Quick-control sections

All section actions are fixed verbs or static argv arrays; no user-provided free-form shell text.

1. **Audio**
   - Show output volume/mute and microphone volume/mute from `pamixer` or compatible PipeWire/PulseAudio CLI.
   - Provide output volume +/-/mute and mic mute actions.
   - Include **Open pavucontrol** fallback.
   - Device enumeration/switching is optional in the first pass; if absent, state this in UI copy or docs.

2. **Network**
   - Show NetworkManager connectivity state and active connection summary from `nmcli` if available.
   - Provide safe common actions only if reliable, e.g. Wi-Fi radio toggle or reconnect, through fixed helper verbs.
   - Include **Open nm-connection-editor** fallback.
   - Do not implement password entry or full Wi-Fi onboarding in this task.

3. **Bluetooth**
   - Show controller powered state and a short connected-device summary from `bluetoothctl` / BlueZ-safe commands if available.
   - Provide controller power toggle only if the command is deterministic and verified.
   - Include **Open blueman-manager** fallback.
   - Pairing, trust, and device browsing can remain fallback-only.

4. **Media**
   - Show MPRIS/player status from `playerctl`: player name, title/artist where available, play/pause state.
   - Provide play/pause, previous, next, and small seek actions using `playerctl`.
   - If no player is available, show “No active player” and keep controls disabled or no-op with status feedback.

5. **Session / power**
   - Provide lock (`hey .lock`), logout/power menu (`wlogout`), display off (`hyprctl dispatch dpms off` or existing Hyprland direct command path), and optionally reboot/shutdown only if routed through an existing reviewed tool or explicit confirmation.
   - Include **Open wlogout** fallback as the primary destructive/session UI.
   - Avoid adding new unconfirmed destructive commands without confirmation.

6. **Basic desktop settings/actions**
   - Include guide, terminal, files, screenshot, screenshot with Swappy, screen recording, fallback launcher, and direct settings fallbacks.
   - These may reuse existing direct commands from `shell.qml` and Stage 2 declared actions, but should remain static argv/fixed helper verbs.

### Helper/status model

Add a small helper, preferably `axiom-control-helper`, near the existing search helper or under a sibling `controls/` directory.

Recommended commands:

```text
axiom-control-helper status
axiom-control-helper audio output-volume +10|-10|mute
axiom-control-helper audio input-volume +10|-10|mute
axiom-control-helper network wifi-toggle
axiom-control-helper bluetooth power-toggle
axiom-control-helper media play-pause|next|previous|seek-forward|seek-back
axiom-control-helper session lock|dpms-off|wlogout
axiom-control-helper osd volume|brightness|media <fields...>
```

`status` returns bounded JSON:

```json
{
  "audio": { "output": { "volume": 42, "muted": false }, "input": { "volume": 30, "muted": false } },
  "network": { "available": true, "state": "connected", "primary": "..." },
  "bluetooth": { "available": true, "powered": true, "connected": ["..."] },
  "media": { "available": true, "player": "...", "status": "Playing", "title": "...", "artist": "..." }
}
```

Missing tools/services must be represented as `available: false` plus a displayable message; QML should degrade to fallback buttons instead of failing the panel.

## Ownership

- **Quickshell (`config/quickshell/axiom-shell/`)** owns visible quick controls, section layout, status rendering, OSD overlay, dock state, user interaction, and invoking fixed helper verbs.
- **Nix (`modules/desktop/quickshell.nix`)** owns helper installation, package dependencies (`pamixer`, `brightnessctl`, `playerctl`, NetworkManager CLI if not already present, `blueman`, `pavucontrol`, `networkmanagerapplet`, `wlogout`, `libnotify` fallback), feature options if introduced, and keeps `quickshell.service` bound to `hyprland-session.target`.
- **Hyprland (`config/hypr/hyprland.conf`)** owns keybindings only: it may call a wrapper/helper for OSD-aware media keys, but it must not become the status/config truth source.
- **Existing `hey .osd` scripts** remain command/fallback compatibility. They may be wrapped to notify Quickshell first, but should still be able to perform the underlying volume/brightness changes and notify-send fallback.

## OSD strategy

- Add `OsdOverlay.qml` as a Quickshell layer surface with transient display for `volume`, `brightness`, and `media` events.
- Add an `IpcHandler` method such as `axiom osd(kind, label, value, icon, detail)` or fixed methods like `showVolume`, `showBrightness`, and `showMedia`. Keep arguments bounded strings/numbers.
- Key path should be: Hyprland binding -> existing command/wrapper mutates state -> wrapper attempts `quickshell ipc -c axiom-shell call axiom ...` -> on IPC failure, existing `hey .osd display` / `notify-send` path runs.
- Volume and brightness bindings should continue to use the existing state-changing scripts or a compatible helper path so `pamixer` and `brightnessctl` behavior is not duplicated inconsistently.
- Media keys currently call `playerctl` directly. Wrap them through a fixed helper/wrapper that runs `playerctl play-pause|next|previous|position ...`, then emits a Quickshell media OSD snapshot. If wrapper/IPC fails, direct `playerctl` behavior must still happen.
- OSD events should not replace notification history; they are ephemeral shell UI and should not create persistent notification entries unless falling back to `notify-send`.

## Fallback behavior

- `nm-connection-editor`: visible button in Network section; direct `Super+N` binding may remain or be changed to quick controls only if a direct fallback binding/action remains.
- `blueman-manager`: visible button in Bluetooth section; direct `Super+Shift+B` may remain as direct fallback.
- `pavucontrol`: visible button in Audio section; direct `Super+C` may remain as direct fallback.
- `wlogout`: visible button in Session/Power section and remains the preferred destructive/session fallback.
- `playerctl`: used for media status/actions and remains the fallback command for media keys if Quickshell IPC fails.
- Existing direct commands (`hey .screenshot`, `hey .screencast`, `hey .lock`, `xdg-open` guide, `fuzzel`) remain reachable either from dock/search or the quick-controls basic actions section.

## Verification plan

- Nix evaluation/build: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Quickshell ownership check: service still in `modules/desktop/quickshell.nix`, still `wantedBy/after/partOf = hyprland-session.target`, expected helper/packages present.
- Helper smoke: run status JSON with missing-tool tolerance; audio/media/network/bluetooth/session fixed verbs in dry-run or safe mode where possible; Python/shell syntax checks for helper/wrappers.
- Hyprland verification: after binding changes, run `Hyprland --verify-config -c config/hypr/hyprland.conf` or generated-config equivalent available in the environment.
- Static scope checks: no upstream installer/framework import, no Stage 4/5 theme/AI/OCR/cloud additions, no unbounded query-derived `sh -lc`, fallbacks still referenced.
- Headless QML/static smoke where possible; record if Wayland/layer-shell prevents runtime execution.
- Live Axiom session checklist: dock quick controls opens/closes, each section displays status or fallback unavailable state, fallback buttons launch, audio/mic changes reflect state, media buttons work with and without active player, OSD appears for volume/brightness/media, Quickshell stopped still leaves direct fallback commands usable, notifications/search regressions absent.

## Rollback plan

- Revert the implementation PR, or switch to the previous NixOS generation.
- Minimal rollback: restore dock `WIFI`/`BT`/`VOL`/`PWR` to direct external commands, hide/remove quick controls panel, and restore media/brightness/volume Hyprland bindings to current `hey .osd` / direct `playerctl` commands.
- If only OSD IPC fails, keep wrapper state changes but force `hey .osd display` / `notify-send` fallback.
- If Quickshell fails entirely, stop/restart `quickshell.service`; Hyprland direct bindings and external tools remain operational.

## Risks and unresolved questions

- Live Quickshell IPC/focus/layer behavior cannot be fully proven headlessly; runtime checklist is required.
- `nmcli`/`bluetoothctl` output and service availability may vary; first pass should tolerate unavailable status and rely on fallbacks.
- Device switching for audio/Bluetooth/network may need a later task if first-pass fixed verbs are insufficient.
- Final helper implementation language/location is open: extend Python helper patterns or use small shell wrappers. Decision should optimize testability and fixed-verb safety.
- Whether to keep direct `Super+C`/`Super+N`/`Super+Shift+B` bindings or repoint them to quick controls is an implementation choice, provided direct fallback remains discoverable.
