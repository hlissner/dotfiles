# Test Report: Axiom Quickshell Search and Actions

Date: 2026-05-09

## Result

PASS with runtime verification gaps. Static, helper, Nix, build, and Hyprland config checks passed. Quickshell live QML and user-session behavior could not be fully verified in this headless/non-Wayland verification environment.

## Checks run

### Python helper syntax and provider smoke

- Command: `python3 -m py_compile config/quickshell/axiom-shell/search/axiom-search-helper.py`
  - Result: PASS, exit 0.
  - Interpretation: helper has valid Python syntax.
- Command: `python3 config/quickshell/axiom-shell/search/axiom-search-helper.py apps list >/dev/null && python3 config/quickshell/axiom-shell/search/axiom-search-helper.py calc '2*(3+4)' && python3 config/quickshell/axiom-shell/search/axiom-search-helper.py emoji list >/dev/null && python3 config/quickshell/axiom-shell/search/axiom-search-helper.py web-url 'hello world'`
  - Result: PASS, exit 0. Calculator returned `{"ok": true, "result": "14"}`; web URL returned `https://duckduckgo.com/?q=hello+world`.
  - Interpretation: apps list, calculator, emoji provider, and web URL encoding provider all execute successfully.
- Command: isolated clipboard smoke using repo-local state under `.legion/tasks/axiom-quickshell-search-actions/.verify-state`, with a repo-local fake `wl-copy` on `PATH` to avoid modifying the user's real clipboard.
  - Result: PASS, exit 0, output `clipboard smoke ok`.
  - Interpretation: `clipboard add`, `list`, `copy`, `clear`, and disabled mode (`AXIOM_CLIPBOARD_HISTORY=0`) work against isolated state without disrupting the user clipboard.

### Diff/static safety checks

- Command: `git diff --check`
  - Result: PASS, exit 0.
  - Interpretation: no whitespace errors in the diff.
- Command: scope greps for installer/downloaded script patterns, Rofi/DMS/Fuzzel paths, and query-derived shell execution.
  - Result: PASS for implementation surfaces. No upstream installer/downloaded script patterns in `config/quickshell/axiom-shell`. No Rofi/DMS matches in modified shell or Hyprland surfaces. Fuzzel fallback is present in `SearchPanel.qml` and `hyprland.conf`. No query-derived `sh -lc` path in `SearchPanel.qml` or `axiom-search-helper.py`; search uses fixed argv/helper commands. The only `sh -lc` match is the pre-existing `root.run(command, label)` dock launcher path in `shell.qml` for static dock commands, not search query execution.
  - Interpretation: implementation respects RFC safety boundaries for provider execution and fallback retention.

### Nix evaluation/build

- Command: `nix-instantiate --parse modules/desktop/quickshell.nix >/dev/null && nix-instantiate --parse flake.nix >/dev/null`
  - Result: PASS, exit 0.
  - Interpretation: modified Nix module and flake parse.
- Command: `nix eval --impure --json .#nixosConfigurations.axiom.config.modules.desktop.quickshell.search.clipboard.enable && nix eval --impure --raw .#nixosConfigurations.axiom.config.systemd.user.services.quickshell.serviceConfig.ExecStart && nix eval --impure --json .#nixosConfigurations.axiom.config.systemd.user.services.quickshell.wantedBy && nix eval --impure --json '.#nixosConfigurations.axiom.config.environment.systemPackages' >/dev/null`
  - Result: PASS, exit 0. Clipboard option evaluated to `true`; quickshell ExecStart evaluated to a store `quickshell --config axiom-shell`; `wantedBy` evaluated to `["hyprland-session.target"]`. Existing repository evaluation warnings were emitted.
  - Interpretation: Quickshell service ownership remains bound to `hyprland-session.target`, search clipboard option is present, and system packages evaluate.
- Command: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
  - Result: PASS, exit 0. Existing evaluation/deprecation warnings were emitted; build completed without linking a result.
  - Interpretation: Axiom system toplevel builds with the quickshell/search changes.

### Quickshell QML smoke

- Command: `quickshell --help`
  - Result: PASS, exit 0.
  - Interpretation: local Quickshell binary is available and supports path-based config selection.
- Command: `timeout 10s quickshell --path config/quickshell/axiom-shell --no-color`
  - Result: FAIL due environment limitation: Qt could not connect to a display / platform plugin initialization failed.
  - Interpretation: cannot run normal Quickshell in this headless verification context.
- Command: `QT_QPA_PLATFORM=offscreen timeout 10s quickshell --path config/quickshell/axiom-shell --no-color`
  - Result: FAIL due environment limitation: `Failed to load configuration ... No PanelWindow backend loaded`.
  - Interpretation: offscreen Qt starts far enough to invoke Quickshell config loading, but layer-shell/PanelWindow backend requires a real supported session; this prevents a credible headless QML runtime smoke here.

### Hyprland config

- Command: `Hyprland --verify-config -c config/hypr/hyprland.conf`
  - Result: PASS, output included `config ok`.
  - Interpretation: modified Hyprland binding syntax verifies. The primary binding attempts Quickshell IPC and falls back to Fuzzel; direct Fuzzel remains on `Super+Shift+Space`.

## Verification gaps

- Live Axiom session behavior was not verified: dock `APP` focus behavior, `Super+Space` IPC focus/open path, app launching, web opening, emoji copy to real clipboard, clipboard persistence across restarts, notification-panel regression behavior, and Fuzzel fallback when Quickshell is stopped.
- Quickshell QML could not be runtime-smoked headlessly because no display/layer-shell `PanelWindow` backend is available in this environment.
