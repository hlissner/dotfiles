# Review Change: axiom-end4-polish-hotfix

## Verdict

PASS

## Findings

### Blocking

None.

### Non-blocking / residual findings

1. **Live graphical behavior remains the main residual risk, but is documented and acceptable for PR handoff.**
   - References: `.legion/tasks/axiom-end4-polish-hotfix/docs/test-report.md:5-7`, `37-41`.
   - Assessment: the verifier could not press `Super+Space`, inspect focus ownership, render tray icons, or view image previews in this non-graphical shell. The report explicitly calls for a post-deployment live smoke test covering launcher input, network/Bluetooth status icons, image preview, preset wallpaper apply/theme generation, and far-left dock placement. This is not blocking because the task contract allows static/package checks plus recorded live-session limits when live UI cannot be exercised (`.legion/tasks/axiom-end4-polish-hotfix/plan.md:45-47`, `67`).

2. **`shell alive` fallback probes prove Quickshell IPC reachability, not every feature handler, but the generated/static evidence covers the intended paths.**
   - References: `config/quickshell/ii/shell.qml:70-74`; `config/hypr/hyprland/keybinds.conf:14-15`, `44`, `59`, `65-74`, `79-81`; `.legion/tasks/axiom-end4-polish-hotfix/docs/test-report.md:14-19`, `23`.
   - Assessment: replacing removed `TEST_ALIVE` calls with a minimal `shell alive` IPC endpoint is appropriate for fallback gating. Handler-specific behavior still depends on the live shell, but `test-report.md` includes static evidence that `startMenu toggle`, `search toggle`, and the generated `Super+Space` chain are present.

3. **Keyboard-focus changes are scoped and plausibly correct, with live focus/dismissal behavior to smoke-test.**
   - References: `config/quickshell/ii/modules/waffle/startMenu/WaffleStartMenu.qml:31-32`, `86-97`; `config/quickshell/ii/modules/ii/overview/Overview.qml:25-28`; `.legion/tasks/axiom-end4-polish-hotfix/docs/test-report.md:28-31`.
   - Assessment: using exclusive layer-shell keyboard focus addresses the reported black/non-responsive launcher path. It may affect click-away or focus-release timing in a live compositor, but that risk is bounded and recorded.

4. **Dock migration mutates user Quickshell config once, which is within scope but should be observed after deployment.**
   - References: `config/quickshell/ii/modules/common/Config.qml:16-21`, `79-81`, `94-96`, `340-346`; `config/quickshell/ii/modules/ii/dock/Dock.qml:53-58`, `73-80`; `.legion/tasks/axiom-end4-polish-hotfix/docs/test-report.md:22`, `33`.
   - Assessment: the migration enables/pins the dock and records `end4PolishDockMigrated`, so it should not repeatedly override later user choices after persistence. Static evidence is adequate; live confirmation of far-left placement remains useful.

## Scope Assessment

The diff stays within the task contract and non-goals:

- Keeps end4 `ii` active rather than restoring the legacy shell, verified by Quickshell service `ExecStart --config ii` and Home Manager source ownership (`.legion/tasks/axiom-end4-polish-hotfix/docs/test-report.md:17-18`, `34-35`).
- Limits changes to Quickshell/end4 integration, generated Hyprland fallback binding, wallpaper/theme paths, cache/temp paths, dock default/migration, and Nix-owned runtime PATH/packages (`config/quickshell/ii/**`, `config/hypr/hyprland/keybinds.conf`, `modules/desktop/hyprland.nix`, `modules/desktop/quickshell.nix`).
- Does not redesign launcher, dock, quick settings, network/Bluetooth UI, wallpaper workflow, or screenshot workflow beyond the reported regressions and requested dock placement.
- Does not change Darwin or unrelated shell/dev modules.

## Security Assessment

Security lens applied because the change touches IPC probes, user service PATH, cache/temp locations, screenshot/clipboard/image handling, and runtime package availability.

- No secrets, credentials, tokens, or generated live artifacts are present in the reviewed diff.
- The systemd user service PATH is Nix-owned and composed from store packages, not writable directories (`modules/desktop/quickshell.nix:104-141`, `228-255`; test evidence at `.legion/tasks/axiom-end4-polish-hotfix/docs/test-report.md:16`, `20`).
- Moving image/clipboard/screenshot temp paths from shared `/tmp/quickshell/...` into XDG cache reduces cross-user temp-path exposure (`config/quickshell/ii/modules/common/Directories.qml:28`, `42-44`). Existing cleanup remains scoped to Quickshell-owned cache subdirectories (`Directories.qml:55-66`).
- Wallpaper selection and theme generation remain repository/Nix-owned paths invoking existing local scripts and `matugen`; no new network or privilege boundary is introduced (`config/quickshell/ii/modules/ii/wallpaperSelector/WallpaperSelectorContent.qml:166-171`; `config/quickshell/ii/services/Wallpapers.qml:18-23`; `config/quickshell/ii/scripts/colors/switchwall.sh`; test evidence at `.legion/tasks/axiom-end4-polish-hotfix/docs/test-report.md:21`, `32`).

## Verification Adequacy

Verification is adequate for PR handoff from this non-graphical environment.

Evidence includes:

- `git diff --check` passed (`test-report.md:13`).
- No remaining `TEST_ALIVE` references in repo/generated/store surfaces (`test-report.md:14`, `23`).
- Generated Hyprland `Super+Space` binding evaluated as `startMenu toggle || search toggle || fuzzel` (`test-report.md:15`).
- Quickshell user service PATH and runtime package closure evaluated, including network/Bluetooth/image/wallpaper/theme tools (`test-report.md:16`, `20`).
- Quickshell service still starts `--config ii`, and Home Manager owns `.config/quickshell/ii` from repository source (`test-report.md:17-18`).
- Static IPC/focus/wallpaper/dock evidence was recorded (`test-report.md:19`, `21-22`, `28-35`).
- Full Axiom NixOS toplevel build passed (`test-report.md:24`).

## Required Follow-up

No blocking follow-up before PR handoff.

Post-deployment live smoke test should confirm the residual graphical paths recorded in `test-report.md:37-41`: launcher typing/focus, network/Bluetooth icon rendering, image preview rendering, preset wallpaper/theme application, and left-pinned dock placement.
