# Review RFC: Axiom Quickshell Search and Actions

## Status

PASS

## Blocking issues

None.

The RFC is implementable, has explicit rollback paths, and covers the main safety boundaries required before engineering: no arbitrary query-to-shell execution, repository-owned declared actions, bounded persistent clipboard state with clear/disable paths, Fuzzel fallback, service ownership preservation, and Stage 1 notification/side-dock regression constraints.

## Non-blocking recommendations for implementation

- Treat `Process.command` argv arrays or fixed helper subcommands as mandatory for search result activation; do not reuse the current `sh -lc` dock launcher helper for query-derived provider data.
- Make the fallback binding concrete in implementation and verify the failure path, not only the happy path: Quickshell IPC failure, Quickshell stopped, and focus failure must still leave Fuzzel reachable.
- Keep provider helpers narrow: fixed subcommands, bounded outputs, no mutable downloaded provider config, no generic “run command” endpoint, and no raw desktop-entry `Exec` parsing in QML.
- For clipboard history, enforce the documented caps, expose clear-all visibly, and verify disable stops the watcher and hides the provider without deleting the whole shell.
- Preserve the Stage 1 layout pattern: separate screen `Variants`/`PanelWindow` for the search panel and regression-check notification panel, dock controls, workspace buttons, clock, and external controls.
- Verification must distinguish static evidence from real-session evidence; if runtime checks cannot run, record why and keep Fuzzel/direct fallback intact.
