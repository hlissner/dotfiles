# Report Walkthrough: Axiom Quickshell Search and Actions

Mode: **implementation**

## Delivery summary

This change implements the RFC Stage 2 direction for an Axiom-native Quickshell search/action surface. The visible launcher path moves from Fuzzel-first to a Quickshell-owned panel opened by the side dock `APP` button and the primary `Super+Space` binding, while retaining Fuzzel as direct fallback and rollback path.

The delivered surface covers the Stage 2 provider set from the contract/RFC: desktop apps, repository-declared local actions, web search, calculator, emoji, and clipboard history. Execution is constrained to fixed helper verbs or reviewed argv arrays rather than free-form query-to-shell execution. Clipboard history is intentionally persistent for function completeness, with caps plus clear and disable paths.

RFC review passed before implementation, with no blockers. Change review also passed with no blocking findings; remaining concerns are runtime-only gaps that require a live Axiom Wayland/layer-shell session.

## Mapping to RFC Stage 2

- **Quickshell-owned search surface**: `shell.qml` now tracks `searchPanelOpen`, exposes IPC methods, and mounts `SearchPanel` in its own screen `Variants`/`PanelWindow`, matching the RFC requirement to preserve the Stage 1 notification layout pattern.
- **Dock and keybinding entrypoints**: the dock `APP` control toggles Quickshell search; Hyprland `Super+Space` calls Quickshell IPC first and falls back to Fuzzel, with `Super+Shift+Space` remaining direct Fuzzel.
- **Provider breadth**: `SearchPanel.qml` combines declared actions, apps, web, calculator, emoji, and clipboard history into a single result list.
- **Fixed-verb execution**: `SearchPanel.qml` invokes `axiom-search-helper` subcommands or static argv command arrays. The helper validates app ids before launch and parses calculator input through a bounded AST allowlist.
- **Clipboard completeness with controls**: Nix enables a user service for text clipboard watching by default, passes finite retention limits through environment variables, and provides `modules.desktop.quickshell.search.clipboard.enable` as the disable path. Search exposes a clear-history action.
- **Fallback-first rollout**: Fuzzel remains installed, has an in-panel fallback action, and remains bound directly.

## Reviewer walkthrough by file / area

### `config/quickshell/axiom-shell/shell.qml`

- Changes `APP` from an external launcher command into a `search` action.
- Adds `searchPanelOpen`, `openSearchPanel`, `toggleSearchPanel`, and IPC methods under target `axiom` so external bindings can open/toggle search.
- Keeps the existing static dock launcher helper in place for pre-existing dock commands; review evidence notes this is not used for query-derived search execution.
- Adds the search panel as a separate `Variants { model: Quickshell.screens }` / `PanelWindow`, leaving the Stage 1 notification panel in its own variants block.

### `config/quickshell/axiom-shell/SearchPanel.qml`

- Implements the UI: focused query input, keyboard navigation, list results, Escape close, Enter activate.
- Declares reviewed local actions: guide, terminal, files, browser, power menu, fallback Fuzzel, and clear clipboard history.
- Loads app, emoji, clipboard, and calculator data through fixed `axiom-search-helper` commands.
- Activates results using fixed commands: app launch by desktop id, copy text for calculator/emoji, clipboard copy/clear by id, DuckDuckGo web URL with encoded query, or static argv actions.

### `config/quickshell/axiom-shell/search/axiom-search-helper.py`

- Provides the repository-owned helper described by the RFC.
- Scans XDG desktop entries, returns normalized app items, and launches only desktop ids present in the scanned set via `gtk-launch` under `uwsm app --` where available.
- Stores clipboard text history under user-local XDG state, capped by environment-provided max entries and max bytes; supports add/list/copy/clear and disabled mode.
- Provides a small static emoji list and a local calculator evaluator that accepts only numeric arithmetic syntax through an AST allowlist.
- Provides a web URL helper used in verification; the QML activation also URL-encodes DuckDuckGo queries directly.

### `modules/desktop/quickshell.nix`

- Keeps `quickshell.service` owned here and bound to `hyprland-session.target`.
- Installs `axiom-search-helper` as a small wrapper around the repository helper and adds needed runtime packages (`wl-clipboard`, `gtk3`, `xdg-utils`, Fuzzel, etc.).
- Adds `modules.desktop.quickshell.search.clipboard` options for enable, max entries, and max entry bytes.
- Adds `axiom-clipboard-history` user service, enabled only when clipboard history is enabled, using `wl-paste --watch ... clipboard add`.

### `config/hypr/hyprland.conf`

- Changes primary launcher binding to `quickshell ipc -c axiom-shell call axiom toggleSearch || fuzzel`.
- Keeps direct Fuzzel on `Super+Shift+Space`.

## Validation evidence

Recorded in `docs/test-report.md`:

- Python helper syntax passed.
- Provider smoke passed for apps list, calculator (`2*(3+4)` -> `14`), emoji list, and web URL encoding.
- Isolated clipboard smoke passed using repo-local state and fake `wl-copy`; covered add, list, copy, clear, and disabled mode without touching the real clipboard.
- Static safety checks passed: no upstream installer/downloaded scripts, no Rofi/DMS primary path in modified launcher surfaces, Fuzzel fallback retained, and no query-derived `sh -lc` path in search implementation.
- Nix parse/eval/build passed, including Axiom toplevel build. Eval confirmed clipboard option defaults to true, quickshell `ExecStart` remains `quickshell --config axiom-shell`, and `wantedBy` remains `hyprland-session.target`.
- Hyprland config verification passed with `config ok`.
- Change review passed with no blockers in `docs/review-change.md`.

## Runtime gaps

The verification environment was headless/non-Wayland. Normal Quickshell startup could not connect to a display, and offscreen startup failed because no layer-shell `PanelWindow` backend was available.

Live Axiom session checks still needed:

- Dock `APP` focus/open behavior.
- `Super+Space` IPC open/toggle behavior.
- Panel focus behavior and keyboard interaction in a real layer-shell session.
- Real app launch and web open behavior.
- Emoji/calc copy to the real clipboard.
- Clipboard persistence across restart plus clear/disable behavior in a real session.
- Notification-panel and side-dock regression behavior.
- Fuzzel fallback when Quickshell is stopped; note that the current binding falls back on IPC command failure, but may not detect a successful IPC call followed by focus failure.

## Risk / security / privacy notes

- **Fixed verbs over shell text**: the new search path avoids arbitrary query-to-shell execution. Results activate through helper subcommands or static argv arrays.
- **Declared actions only**: local actions are reviewed in `SearchPanel.qml`; there is no generic “run command” endpoint or downloaded provider config.
- **App launch validation**: helper launch validates the desktop id against scanned desktop entries before invoking `gtk-launch`.
- **Calculator safety**: calculator input is treated as data and limited to arithmetic tokens and AST nodes, not Python eval on arbitrary code.
- **Clipboard privacy**: clipboard history intentionally persists user text under user-local state for function completeness. This may store sensitive data. Mitigations are finite caps, deduplication, visible clear history, disable option, and rollback/removal steps.
- **Residual runtime risk**: focus behavior and fallback edge cases depend on a real Axiom session and remain explicitly unverified.

## Rollback notes

- Full rollback: revert the implementation PR or switch to a prior NixOS generation.
- Minimal launcher rollback: restore dock `APP` and `Super+Space` to direct `fuzzel`, and keep/use `Super+Shift+Space` direct Fuzzel.
- Clipboard/privacy rollback: use the clear-history action, disable `modules.desktop.quickshell.search.clipboard.enable`, stop the `axiom-clipboard-history` user service if running, and remove `$XDG_STATE_HOME/axiom-shell/clipboard-history.json` or the containing Axiom shell state directory if appropriate.
- If only Quickshell is unhealthy, restart/stop `quickshell.service`; Fuzzel remains available as fallback.
