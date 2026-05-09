# Review Change: Axiom Quickshell Search and Actions

## Status

PASS

## Findings / blockers

No blocking findings.

- Contract/RFC alignment is acceptable: Quickshell remains service-owned by `modules/desktop/quickshell.nix` and bound to `hyprland-session.target` (`modules/desktop/quickshell.nix:51-65`), the dock `APP` control opens the Quickshell search panel (`config/quickshell/axiom-shell/shell.qml:19-20`, `config/quickshell/axiom-shell/shell.qml:109-113`), and search is implemented as a separate screen `Variants` / `PanelWindow` rather than destabilizing the Stage 1 notification panel (`config/quickshell/axiom-shell/shell.qml:319-354`, `config/quickshell/axiom-shell/shell.qml:356-390`).
- Arbitrary command/query execution risk is controlled for the new search surface: result activation uses fixed argv/helper verbs (`config/quickshell/axiom-shell/SearchPanel.qml:85-103`), app launch validates desktop ids from a scanned set before invoking `gtk-launch` (`config/quickshell/axiom-shell/search/axiom-search-helper.py:102-111`), calculator input is parsed through a bounded AST allowlist (`config/quickshell/axiom-shell/search/axiom-search-helper.py:165-200`), and there is no query-derived `sh -lc` path in the search implementation. The remaining `sh -lc` helper is the pre-existing static dock launcher path (`config/quickshell/axiom-shell/shell.qml:37-40`).
- Clipboard requirements are met: persistent user-local history is capped by Nix-provided environment defaults (`modules/desktop/quickshell.nix:28-32`, `modules/desktop/quickshell.nix:61-65`, `modules/desktop/quickshell.nix:73-77`), entries are truncated and capped on write (`config/quickshell/axiom-shell/search/axiom-search-helper.py:126-138`), clear is exposed in search (`config/quickshell/axiom-shell/SearchPanel.qml:26`, `config/quickshell/axiom-shell/SearchPanel.qml:93-96`), and the Nix disable path both stops the watcher and hides provider state via `AXIOM_CLIPBOARD_HISTORY=0` (`modules/desktop/quickshell.nix:62`, `modules/desktop/quickshell.nix:68-83`, `config/quickshell/axiom-shell/search/axiom-search-helper.py:141-144`).
- Fuzzel fallback is retained in both UI and binding paths: search includes a direct fallback action (`config/quickshell/axiom-shell/SearchPanel.qml:25`), `Super+Space` attempts Quickshell IPC then falls back to Fuzzel, and `Super+Shift+Space` remains direct Fuzzel (`config/hypr/hyprland.conf:134-135`).
- Verification evidence is credible for this environment: helper syntax/provider smoke, isolated clipboard smoke, static safety checks, Nix parse/eval/build, and Hyprland config verification passed (`docs/test-report.md:11-42`, `docs/test-report.md:56-60`). The report clearly separates headless Quickshell/runtime gaps from completed checks (`docs/test-report.md:44-65`).

## Security / privacy view

Security lens applied because this change introduces clipboard-history persistence and command/action execution surfaces. The implementation keeps execution behind fixed local verbs/argv arrays and repository-declared actions, does not download remote scripts, and does not execute free-form user query text as shell. Clipboard history persists sensitive text under user-local state by design; this is consistent with the accepted single-user/function-completeness contract, with caps, clear, disable, and rollback paths present.

## Residual runtime risks

- Live Wayland/layer-shell behavior was not verified: panel focus, dock `APP` behavior, IPC open/toggle, notification regression, real app launch, real clipboard copy/persistence, and stopped-Quickshell fallback still need an Axiom session check (`docs/test-report.md:62-65`).
- The `Super+Space` fallback only covers IPC command failure; a successful IPC call followed by focus failure may not automatically open Fuzzel (`config/hypr/hyprland.conf:134`). This is a known runtime risk rather than a blocker because direct Fuzzel remains bound.
- Clipboard history intentionally stores sensitive text persistently. Users should clear history or disable `modules.desktop.quickshell.search.clipboard.enable` when privacy is preferred over completeness.
