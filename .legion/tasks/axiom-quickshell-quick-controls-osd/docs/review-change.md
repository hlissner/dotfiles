# Review Change: Axiom Quickshell Quick Controls and OSD

Date: 2026-05-09
Worktree: `/home/c1/dotfiles/.worktrees/axiom-quickshell-quick-controls-osd`

## Status

PASS

## Findings / blockers

None blocking.

The implementation aligns with the Stage 3 contract and accepted RFC: dock quick-control entries now route to Quickshell quick controls (`config/quickshell/axiom-shell/shell.qml:19-28`, `config/quickshell/axiom-shell/shell.qml:122-158`), the panel covers audio/network/Bluetooth/media/session/basic actions with visible fallbacks (`config/quickshell/axiom-shell/QuickControlsPanel.qml:131-215`), and OSD IPC is added without replacing the existing `hey .osd` compatibility path (`config/hypr/bin/osd.zsh:19-43`).

## Readiness review

- **Contract/RFC alignment:** PASS. The change stays inside the declared Linux/Axiom files, adds focused QML components instead of replacing the shell root, preserves Stage 1 notifications and Stage 2 search surfaces, and keeps one `PanelWindow` per `Variants` block (`config/quickshell/axiom-shell/shell.qml:245-511`).
- **DBus/control scope:** PASS. Network/Bluetooth/media/audio are shallow helper-backed status/actions rather than deep DBus managers; full network onboarding, pairing, and device switching remain fallback-led as allowed by the RFC (`config/quickshell/axiom-shell/controls/axiom-control-helper.py:41-73`, `config/quickshell/axiom-shell/QuickControlsPanel.qml:151-170`).
- **Command execution boundaries:** PASS. New helper actions are fixed-verb/static argv and use a centralized `subprocess.run` wrapper with no shell string execution (`config/quickshell/axiom-shell/controls/axiom-control-helper.py:13-14`, `config/quickshell/axiom-shell/controls/axiom-control-helper.py:94-155`). New QML panel actions use fixed helper args or static argv (`config/quickshell/axiom-shell/QuickControlsPanel.qml:26-38`). Existing `sh -lc` launcher behavior remains in the pre-existing dock launcher path (`config/quickshell/axiom-shell/shell.qml:44-48`) and is not widened with user-controlled input.
- **OSD fallback semantics and media-key regression risk:** PASS. Volume/brightness bindings still call `hey .osd`, so the existing state-changing scripts remain authoritative (`config/hypr/hyprland.conf:315-322`). `hey.osd.display` now attempts Quickshell IPC first and falls back to `notify-send` if IPC is unavailable or fails (`config/hypr/bin/osd.zsh:31-42`). Media keys route through `axiom-control-helper media ...`, which invokes fixed `playerctl` verbs before attempting OSD IPC, preserving direct media behavior if Quickshell is absent (`config/hypr/hyprland.conf:323-328`, `config/quickshell/axiom-shell/controls/axiom-control-helper.py:129-144`).
- **External fallback preservation:** PASS. The panel keeps `pavucontrol`, `nm-connection-editor`, `blueman-manager`, `wlogout`, `playerctl`, `fuzzel`, screenshot, record, lock, guide, terminal, and files reachable through visible buttons or fixed helper paths (`config/quickshell/axiom-shell/QuickControlsPanel.qml:143-156`, `config/quickshell/axiom-shell/QuickControlsPanel.qml:168-213`).
- **Nix/Quickshell/Hyprland ownership:** PASS. Nix installs the helper and packages while keeping `quickshell.service` bound to `hyprland-session.target` (`modules/desktop/quickshell.nix:23-29`, `modules/desktop/quickshell.nix:43-61`, `modules/desktop/quickshell.nix:63-78`). Quickshell owns UI/OSD, and Hyprland changes are limited to keybinding routing (`config/hypr/hyprland.conf:313-328`).
- **Stage 1/2 regression risk:** PASS with runtime caveat. Static composition preserves existing dock, notification panel, search panel, IPC search methods, and separate panel windows (`config/quickshell/axiom-shell/shell.qml:97-120`, `config/quickshell/axiom-shell/shell.qml:192-214`, `config/quickshell/axiom-shell/shell.qml:375-478`). Live focus/layer behavior is not proven headlessly.
- **Verification credibility:** PASS. Evidence includes helper syntax/smoke, OSD zsh syntax, diff hygiene, Nix parse/eval/build, Hyprland verify-config, Quickshell CLI availability, qmllint, scope/fallback greps, and Variants composition checks (`docs/test-report.md:12-29`). The report does not overclaim runtime coverage and records the necessary live-session checklist (`docs/test-report.md:31-36`).

## Security / safety view

Security lens applied because this introduces local system control actions. The change does not introduce remote scripts, network downloads, arbitrary command execution from user input, or new privilege boundaries. Local actions are constrained to reviewed fixed verbs and existing desktop tools. Destructive/session actions are limited to lock, DPMS off, and opening `wlogout`; no new direct reboot/shutdown commands are added (`config/quickshell/axiom-shell/controls/axiom-control-helper.py:147-155`). Residual safety concern is ordinary local-session impact from toggling Wi-Fi/Bluetooth/audio/display state, which is expected for a quick-controls surface and should be validated live.

## Residual runtime risks

- Live Quickshell layer-shell placement, focus behavior, multi-screen visibility, and panel close/open interaction remain unproven in the headless environment.
- Live OSD rendering and IPC timing for rapid volume/brightness/media key repeats remain unproven; fallback notification behavior is statically credible but should be checked in-session.
- `nmcli`, `bluetoothctl`, `pamixer`, `playerctl`, and device/service availability may vary across real sessions; unavailable states should degrade to fallback tools as designed.
- Disruptive controls such as Wi-Fi toggle, Bluetooth power toggle, lock, DPMS off, and `wlogout` launch were intentionally not executed during verification.
