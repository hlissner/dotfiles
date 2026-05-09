# Report Walkthrough: Axiom Quickshell Quick Controls and OSD

Date: 2026-05-09
Mode: implementation
Worktree: `/home/c1/dotfiles/.worktrees/axiom-quickshell-quick-controls-osd`

## Delivery status

**Ready for reviewer pass, with live-session runtime gaps recorded.**

This walkthrough summarizes the already-implemented Stage 3 change and cites the accepted RFC, verification report, and readiness review. It does not add new design or validation evidence.

Primary evidence:

- Contract: `.legion/tasks/axiom-quickshell-quick-controls-osd/plan.md`
- RFC: `.legion/tasks/axiom-quickshell-quick-controls-osd/docs/rfc.md`
- RFC review: `.legion/tasks/axiom-quickshell-quick-controls-osd/docs/review-rfc.md`
- Test report: `.legion/tasks/axiom-quickshell-quick-controls-osd/docs/test-report.md`
- Change review: `.legion/tasks/axiom-quickshell-quick-controls-osd/docs/review-change.md`

## What changed and why

Stage 3 moves Axiom beyond dock buttons that only launch external settings tools. The contract required Quickshell-owned quick controls and OSD for audio, network, Bluetooth, media, session/power, and basic desktop actions while preserving existing Stage 1 notification center, Stage 2 search/actions, Hyprland media keys, and external fallbacks (`plan.md:17-26`).

The accepted RFC chose **Option C: Quickshell UI + small fixed-verb control helper + external fallbacks** (`rfc.md:51-60`). The RFC review passed that approach because it rejected deep DBus/control-center parity, preserved fallbacks, kept OSD rollback paths, and constrained actions to fixed helper verbs/static argv (`review-rfc.md:5-20`).

The implementation follows that path:

- Dock quick-control entries now route to Quickshell quick controls instead of only launching external tools (`review-change.md:14`).
- Quick controls cover audio, network, Bluetooth, media, session/power, and basic actions with visible fallback tools (`review-change.md:14`, `review-change.md:22`).
- OSD IPC is added while preserving the existing `hey .osd` compatibility/fallback path (`review-change.md:21`).
- Nix still owns Quickshell service/package/helper wiring, and Hyprland changes remain limited to keybinding routing (`review-change.md:23`).

## RFC Stage 3 mapping

| RFC / contract expectation | Delivery evidence |
|---|---|
| Quickshell remains Nix-owned and bound to `hyprland-session.target` | Nix eval confirmed `wantedBy`, `after`, and `partOf` all remain `hyprland-session.target`; full Axiom toplevel build passed (`test-report.md:20-21`). |
| Preserve side dock, workspaces, notifications, search, clock, launcher/search fallbacks | Static composition review found existing surfaces preserved and one `PanelWindow` per `Variants`; live focus/layer behavior remains a recorded runtime gap (`review-change.md:24`, `test-report.md:28`, `test-report.md:31-36`). |
| Dock controls open Quickshell quick controls first | Review confirms dock quick-control entries route to Quickshell quick controls (`review-change.md:14`, `review-change.md:18`). |
| Quick controls expose audio/network/Bluetooth/media/session/basic actions | Review confirms panel coverage and visible fallbacks (`review-change.md:14`, `review-change.md:22`). |
| External fallbacks stay reachable | Fallback grep passed and review lists `pavucontrol`, `nm-connection-editor`, `blueman-manager`, `wlogout`, `playerctl`, `fuzzel`, screenshot, record, lock, guide, terminal, and files (`test-report.md:27`, `review-change.md:22`). |
| Volume/brightness/media feedback routes toward Quickshell OSD without breaking key behavior | Hyprland config verification passed; review confirms volume/brightness still use `hey .osd`, and media helper invokes `playerctl` verbs before attempting OSD IPC (`test-report.md:22`, `review-change.md:21`). |
| No Stage 4/5 expansion or upstream framework import | Scope grep passed with no added installer/download script, Stage 4/5 theme/AI/OCR/cloud additions, or new generic `sh -lc` runner (`test-report.md:26`). |
| Record credible validation and live gaps | Test report is PASS with recorded runtime gaps and explicitly lists headless limitations (`test-report.md:6-8`, `test-report.md:31-36`). |

## Reviewer walkthrough by file / area

### `config/quickshell/axiom-shell/shell.qml`

- Composition root remains focused; new quick controls and OSD surfaces are added as separate `Variants` / `PanelWindow` blocks rather than turning the shell root into a monolith.
- Dock quick-control entries now route to the Quickshell quick controls panel (`review-change.md:14`, `review-change.md:18`).
- Existing Stage 1/2 surfaces are preserved statically: side dock, notification panel, search panel, IPC search methods, and separate panel windows (`review-change.md:24`).
- Static Variants check passed with `Variants 5`, `PanelWindow 5`, preserving the previously required one-window-per-variant pattern (`test-report.md:28`).

### `config/quickshell/axiom-shell/QuickControlsPanel.qml`

- Provides the Stage 3 quick-control surface: audio, network, Bluetooth, media, session/power, and basic desktop actions.
- Uses fixed helper args or static argv for actions instead of query-derived shell execution (`review-change.md:20`).
- Keeps fallback tools visible and reachable, including `pavucontrol`, `nm-connection-editor`, `blueman-manager`, `wlogout`, `playerctl`, `fuzzel`, screenshot/record/lock, guide, terminal, and files (`review-change.md:22`).
- Does not attempt full network onboarding, Bluetooth pairing, or audio/device switching parity; those remain intentionally fallback-led per the RFC (`rfc.md:80-92`, `review-change.md:19`).

### `config/quickshell/axiom-shell/OsdOverlay.qml`

- Adds Quickshell-owned transient OSD UI for volume, brightness, and media feedback, matching the RFC OSD strategy (`rfc.md:145-152`).
- Static QML lint passed for `shell.qml`, `QuickControlsPanel.qml`, and `OsdOverlay.qml` (`test-report.md:24`).
- Live layer-shell rendering and IPC timing were not proven because the environment had no usable display (`test-report.md:25`, `test-report.md:31-34`).

### `config/quickshell/axiom-shell/controls/axiom-control-helper.py`

- Implements the bounded control-helper pattern selected by the RFC: status snapshots and fixed local verbs rather than broad DBus managers (`rfc.md:108-137`, `review-change.md:19`).
- Helper syntax, status JSON, usage errors, invalid media verb rejection, and safe media verbs passed smoke checks (`test-report.md:14-16`).
- Subprocess execution is centralized through a fixed-argv wrapper; review and AST scan found no new shell string runner (`review-change.md:20`, `test-report.md:29`).
- Local system control verbs are intentionally narrow; disruptive toggles were not executed during headless verification (`test-report.md:31-36`).

### `modules/desktop/quickshell.nix`

- Installs the helper and required desktop/control packages while preserving Quickshell service ownership (`review-change.md:23`).
- Nix module parse, service target eval, toplevel drvPath eval, and full Axiom NixOS build passed (`test-report.md:19-21`).
- Service binding remains `wantedBy/after/partOf = [ "hyprland-session.target" ]` (`test-report.md:20`).

### `config/hypr/hyprland.conf`

- Media-key changes are limited to routing through existing/wrapped control paths; Hyprland remains keybinding owner rather than status/control truth source (`review-change.md:21`, `review-change.md:23`).
- Hyprland config verification passed with `config ok` (`test-report.md:22`).
- Volume/brightness still call `hey .osd`, preserving existing state-changing behavior; media keys call fixed helper media verbs that preserve `playerctl` semantics before OSD IPC (`review-change.md:21`).

### `config/hypr/bin/osd.zsh`

- Keeps the compatibility wrapper path for existing OSD usage.
- Attempts Quickshell IPC first, then falls back to the existing `notify-send` path if IPC is unavailable or fails (`review-change.md:21`).
- zsh syntax check passed (`test-report.md:17`).

## Validation evidence

The verification result is **PASS with recorded runtime gaps** (`test-report.md:6-8`). Evidence includes:

- Python helper syntax and helper smoke checks (`test-report.md:14-16`).
- OSD wrapper zsh syntax (`test-report.md:17`).
- `git diff --check` whitespace/diff hygiene (`test-report.md:18`).
- Nix module parse, service ownership eval, toplevel eval, and full Axiom build (`test-report.md:19-21`).
- Hyprland `--verify-config` (`test-report.md:22`).
- Quickshell CLI availability and QML static lint (`test-report.md:23-24`).
- Scope grep for no upstream installer/framework, Stage 4/5 additions, or new generic shell runner (`test-report.md:26`).
- Fallback/ownership grep for expected tools, helper, and service target references (`test-report.md:27`).
- Variants composition and helper subprocess shape checks (`test-report.md:28-29`).

## Runtime gaps

The environment could not validate live Wayland/layer-shell behavior. `quickshell --path config/quickshell/axiom-shell` selected the worktree config but failed before runtime QML/layer-shell validation because Qt could not connect to a display or initialize a platform plugin (`test-report.md:25`).

Live Axiom session checks still needed:

- Quick-controls panel open/close, section switching, layer position, focus behavior, and multi-screen visibility.
- OSD rendering and IPC timing for rapid volume/brightness/media key repeats.
- Stage 1/2 regressions: side dock, workspaces, notification panel, search panel, Fuzzel fallback.
- Fallback buttons launching expected apps.
- Media behavior with and without an active MPRIS player.
- Quickshell-unavailable path where `hey .osd` / `notify-send` and direct `playerctl` behavior continue to work.
- Disruptive controls that were intentionally not executed headlessly: Wi-Fi toggle, Bluetooth power toggle, output/input volume mutation, lock, DPMS off, and `wlogout` launch (`test-report.md:31-36`).

## Risk and safety notes

- **Local system control actions:** The change introduces expected local-session controls for audio, network, Bluetooth, display/session, and media. Review found no remote scripts, downloads, arbitrary user-input command execution, or privilege-boundary changes (`review-change.md:27-29`).
- **Command boundaries:** New actions are fixed helper verbs/static argv. Existing pre-existing `sh -lc` launcher behavior was not widened with user-controlled input (`review-change.md:20`).
- **Destructive/session safety:** New direct destructive commands are not added. Session actions are limited to lock, DPMS off, and opening `wlogout`; `wlogout` remains the preferred destructive/session fallback (`review-change.md:29`).
- **OSD/media-key fallback safety:** Volume/brightness bindings still use existing `hey .osd` state-changing scripts, and media helper verbs run `playerctl` before attempting Quickshell OSD IPC. If IPC fails, fallback notification/direct behavior remains the safety path (`review-change.md:21`).
- **Service variability:** `nmcli`, `bluetoothctl`, `pamixer`, `playerctl`, and real device/service availability may vary; unavailable states should degrade to fallback tools as designed (`review-change.md:35`).

## Rollback notes

Rollback is intentionally simple and matches the RFC (`rfc.md:173-178`):

1. Revert the implementation PR or boot/switch to the previous NixOS generation.
2. Minimal UI rollback: restore dock `WIFI` / `BT` / `VOL` / `PWR` entries to direct external commands and hide/remove the quick-controls panel.
3. OSD-only rollback: keep underlying state-changing wrapper behavior but force `hey .osd display` / `notify-send` fallback instead of Quickshell IPC.
4. Media-key rollback: restore Hyprland media bindings to direct `hey .osd` / `playerctl` commands.
5. If Quickshell fails entirely, stop/restart `quickshell.service`; external tools and Hyprland direct bindings remain the operational fallback.
