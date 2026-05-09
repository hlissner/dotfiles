# Test Report: Axiom Quickshell Quick Controls and OSD

Date: 2026-05-09
Worktree: `/home/c1/dotfiles/.worktrees/axiom-quickshell-quick-controls-osd`

## Result

**PASS with recorded runtime gaps.** Static, helper, Hyprland, and Nix validation passed. Live Quickshell/layer-shell behavior could not be proven in this headless/non-display environment.

## Commands and evidence

| Check | Command | Result | Interpretation |
|---|---|---|---|
| Python helper syntax | `python3 -m py_compile config/quickshell/axiom-shell/controls/axiom-control-helper.py` | PASS, no output | Helper parses under Python. |
| Helper status/usage/media smoke | `python3 config/quickshell/axiom-shell/controls/axiom-control-helper.py status; python3 .../axiom-control-helper.py; python3 .../axiom-control-helper.py media bogus; python3 .../axiom-control-helper.py media play-pause` | PASS for `status`; usage errors printed for missing args and invalid media verb; safe media path returned without disruptive network/Bluetooth/audio actions. Status JSON included audio, network, Bluetooth, and no-active-player media state. | Helper exposes bounded JSON and rejects invalid verbs with usage. Mutating network/Bluetooth/audio toggles were intentionally not run. |
| Safe media behavior with PATH stubs | Created temporary repo-local stubs under `.legion/tasks/axiom-quickshell-quick-controls-osd/verify-stubs-20260509`, then ran `PATH="$PWD/.legion/tasks/axiom-quickshell-quick-controls-osd/verify-stubs-20260509:$PATH" python3 config/quickshell/axiom-shell/controls/axiom-control-helper.py status`, `media play-pause`, `media next`, `media previous`; removed stubs via Python cleanup. | PASS; no active player status was tolerated and media verbs completed with stubbed `playerctl`. | Confirms media wrapper can run safe fixed verbs without requiring a real MPRIS player. |
| OSD zsh syntax | `zsh -n config/hypr/bin/osd.zsh` | PASS, no output | Modified OSD wrapper is syntactically valid zsh. |
| Whitespace/diff hygiene | `git diff --check` | PASS, no output | No whitespace errors in the diff. |
| Nix module parse | `nix-instantiate --parse modules/desktop/quickshell.nix >/dev/null` | PASS | Modified Nix module parses. |
| Quickshell service ownership eval | `nix eval --impure .#nixosConfigurations.axiom.config.systemd.user.services.quickshell.wantedBy --json`; same for `after` and `partOf`; `nix eval --impure .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath --raw` | PASS. `wantedBy`, `after`, and `partOf` all evaluate to `["hyprland-session.target"]`; toplevel drvPath evaluates. Warnings are pre-existing Nixpkgs/deprecation style warnings. | Service remains owned by Nix and bound to `hyprland-session.target`; full system evaluation succeeds. |
| Axiom build | `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel` | PASS; built `/nix/store/5cl5rww9ivx3hsr711yrb42hskvvm3h1-nixos-system-axiom-25.11.20260203.e576e3c.drv`. Removed generated `result` symlink after build. | Full Axiom NixOS toplevel builds with the helper/package/service changes. |
| Hyprland config | `Hyprland --verify-config -c config/hypr/hyprland.conf` | PASS: `config ok` | Modified media-key bindings and existing config parse for Hyprland. |
| Quickshell CLI availability | `quickshell --help` | PASS | Quickshell binary is present. |
| Quickshell/QML static lint | `qmllint config/quickshell/axiom-shell/shell.qml config/quickshell/axiom-shell/QuickControlsPanel.qml config/quickshell/axiom-shell/OsdOverlay.qml` | PASS, no output | Modified QML files pass available static lint. |
| Quickshell runtime smoke | `timeout 5s quickshell --path config/quickshell/axiom-shell` | LIMITATION: Quickshell selected the worktree config, then failed before QML/layer-shell validation because Qt could not connect to a display / initialize a platform plugin (`could not connect to display`, `no Qt platform plugin could be initialized`). | Headless environment cannot prove live layer-shell windows, panel focus, IPC OSD display, or runtime component wiring. Requires live Axiom session check. |
| Scope grep | `git diff -U0 -- config/quickshell/axiom-shell config/hypr modules/desktop/quickshell.nix | rg -n 'curl|wget|installer|install\.sh|end-4|matugen|wallpaper|dynamic|AI|OCR|cloud|translation|openai|anthropic|sh -lc'` | PASS, no matches in added diff. | No upstream installer/download script, Stage 4/5 theme/AI/OCR/cloud additions, or new added `sh -lc` generic runner detected. |
| Fallback and ownership grep | `rg -n 'nm-connection-editor|blueman-manager|pavucontrol|wlogout|playerctl|axiom-control-helper|hyprland-session.target|quickshell.service' config/quickshell/axiom-shell config/hypr modules/desktop/quickshell.nix` | PASS; expected fallback tools, helper install/use, and service target references are present. | External fallbacks remain referenced and helper/service ownership is visible. |
| Variants composition | Python count of `Variants {` and `PanelWindow {` in `config/quickshell/axiom-shell/shell.qml` | PASS: `Variants 5`, `PanelWindow 5`. | Static check preserves the one-`PanelWindow`-per-`Variants` pattern. |
| Helper subprocess shape | AST scan of `subprocess.*` calls in `axiom-control-helper.py` | PASS: only `subprocess.run` wrapper at line 14. | Helper centralizes subprocess execution through a fixed-argv wrapper; no new shell string runner was detected in the helper. |

## Verification gaps / live-session checklist

- Live Quickshell quick-controls panel open/close, section switching, focus/layer position, and interaction were not verified because there is no usable display/Wayland session in this environment.
- Live OSD IPC rendering for volume/brightness/media was not verified for the same Qt/display limitation.
- Destructive or disruptive toggles were intentionally not run: Wi-Fi toggle, Bluetooth power toggle, output/input volume mutation, lock, DPMS off, and wlogout launch.
- A live Axiom session should confirm side dock, workspaces, notifications, Stage 2 search/Fuzzel fallback, quick-control fallback buttons, media keys with and without active player, and OSD fallback behavior when Quickshell IPC is unavailable.
