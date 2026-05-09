# RFC: Axiom Quickshell Search and Actions

> Status: draft for `review-rfc`
> Task: `.legion/tasks/axiom-quickshell-search-actions/`
> Contract: `.legion/tasks/axiom-quickshell-search-actions/plan.md`

## Context and evidence

- Parent Stage 2 calls for shell-owned search supporting apps, actions, web, calculator, clipboard, and emoji while retaining Fuzzel fallback: `.legion/tasks/dots-hyprland-desktop-rfc/docs/rfc.md:100-118`.
- The task contract makes this the implementation gate and explicitly prefers function completeness over strict clipboard privacy minimization on a single-user local machine: `.legion/tasks/axiom-quickshell-search-actions/plan.md:21-26`, `.legion/tasks/axiom-quickshell-search-actions/plan.md:30-39`.
- Current `APP` dock control still executes `fuzzel`: `config/quickshell/axiom-shell/shell.qml:19-28`.
- Current launcher execution is `Process` + `sh -lc`: `config/quickshell/axiom-shell/shell.qml:36-40`; Stage 2 should not extend this pattern to arbitrary query execution.
- Stage 1 notification center is present and must be preserved: `config/quickshell/axiom-shell/shell.qml:125-147`, `config/quickshell/axiom-shell/NotificationPanel.qml:1-292`.
- Prior side-dock regression showed `Variants`/`PanelWindow` composition is fragile; new search panel should use its own screen variants and not colocate multiple sibling windows under one delegate: `.legion/tasks/axiom-quickshell-side-dock-regression/plan.md:7-24`.
- Quickshell service/package ownership is already in `modules/desktop/quickshell.nix:23-58`; it binds `quickshell.service` to `hyprland-session.target` at `modules/desktop/quickshell.nix:35-45`.
- Hyprland currently owns the `Super+Space` binding to Fuzzel: `config/hypr/hyprland.conf:130-141`.
- `wl-clipboard` is already in Hyprland packages: `modules/desktop/hyprland.nix:109-122`; Fuzzel is in Quickshell packages: `modules/desktop/quickshell.nix:24-33`.

## Goals

- Make Quickshell the primary visible search/action surface opened from the dock `APP` button and the primary launcher keybinding.
- Provide one panel with providers for desktop apps, declared local actions, web search, calculator, emoji, and clipboard history.
- Keep implementation small, task-local, and reviewable; avoid importing upstream shell frameworks, installers, or mutable downloaded scripts.
- Preserve Stage 1 side dock, notification center, workspace buttons, clock, and external controls.
- Keep Fuzzel available as a reliable fallback and rollback path.

## Non-goals

- No Rofi/DMS primary shell path.
- No arbitrary shell execution from user query text.
- No cloud/AI/OCR/screen translation/capture workflow expansion.
- No Hyprland/UWSM/greetd service ownership redesign.
- No full desktop-entry edge-case project beyond common GUI apps.

## Options considered

### Option A: Keep Fuzzel primary, add a few dock actions

Lowest risk, but fails the Stage 2 goal because Quickshell would not own search/actions and calculator/emoji/clipboard would remain fragmented.

### Option B: Import an upstream launcher/action framework

Fastest feature breadth, but conflicts with the parent RFC: large opaque framework, non-Nix assumptions, generated state, and hard-to-review behavior.

### Option C: Quickshell UI with repository-owned provider helpers

Quickshell owns the panel and interaction model; Nix owns packages/services; small repository-owned helpers expose bounded JSON provider data and fixed verbs. This handles Quickshell API uncertainty without making QML parse every desktop/system format.

### Decision

Choose **Option C**. It preserves Axiom ownership boundaries, keeps action execution declarative, supports function completeness, and leaves Fuzzel as fallback.

## Proposed design

### UI and composition

- Keep `shell.qml` as composition root, but add focused local components under `config/quickshell/axiom-shell/`, e.g. `SearchPanel.qml`, `SearchResultDelegate.qml`, and small provider/model glue files.
- Add the search panel as a separate `Variants { model: Quickshell.screens }` block with one `PanelWindow` delegate, mirroring the post-regression pattern used for notifications.
- The panel opens adjacent to the side dock, has a focused query field, keyboard navigation, provider section labels, and explicit result activation.
- `APP` dock button toggles the panel directly in Quickshell; notification panel behavior remains unchanged.

### Provider model

All providers return normalized items:

```text
{ id, provider, title, subtitle, icon?, keywords?, action }
```

`action` is not shell text. It is a fixed verb plus bounded arguments, for example `{ verb: "launchApp", desktopId }` or `{ verb: "copyText", text }`.

- **Apps**: scan desktop entries from XDG application directories through a local helper/provider. Results include name, generic name/comment, desktop id, and optional icon. Activation uses a desktop-entry launcher such as `gtk-launch`/equivalent under `uwsm app --`, not raw `Exec` strings assembled from query text.
- **Declared actions**: load a repository-owned allowlist, preferably `config/quickshell/axiom-shell/search/actions.json` or a nearby QML/JS data file. Initial actions must cover guide, terminal, files, browser/web search, power/session, and fallback launcher. Commands are argv arrays or fixed verbs; only explicitly declared placeholders are allowed.
- **Web search**: when query is non-empty, show configured web search actions. Activation URL-encodes the query and opens a declared search URL with `xdg-open` or the declared browser. Network access is only the user-requested browser navigation, not a downloaded script.
- **Calculator**: use a local calculator backend, preferably `qalc`/libqalculate, with fixed argv and a timeout. Calculator input is data, never shell script. Result activation copies the result and may optionally replace the query.
- **Emoji**: use a local static emoji dataset shipped in the repository or from a Nix package. Activation copies the selected Unicode text via `wl-copy`; it should not require network access.
- **Clipboard history**: use a local bounded history service/helper. The provider lists stored text/URI entries; activation copies the selected entry back to the clipboard. It must expose clear-all and disable paths.

### Execution safety

- Do not pass arbitrary query text to `sh -lc`.
- Prefer `Process.command` argv arrays or a small fixed helper CLI with subcommands like `apps list`, `apps launch <desktop-id>`, `clipboard list`, `clipboard copy <id>`, `clipboard clear`.
- Declared actions may execute local commands, but only from the reviewed allowlist. Free-form command execution is out of scope.

## Ownership

- **Quickshell (`config/quickshell/axiom-shell/`)** owns the visible panel, result model composition, keyboard/mouse interactions, dock `APP` behavior, and invoking fixed provider verbs.
- **Nix (`modules/desktop/quickshell.nix`)** owns packages, helper installation, user services/timers needed by search providers, and feature enable/disable options. It must keep `quickshell.service` under `hyprland-session.target`.
- **Hyprland (`config/hypr/hyprland.conf` and only if needed `modules/desktop/hyprland.nix`)** owns launcher keybindings and fallback wiring only. It should not become the provider/config truth source.
- **Provider config** lives in the repository near the shell source so it is reviewable and versioned. Runtime state lives under XDG state/cache, not in the repository.

## Clipboard policy

Given the user preference, clipboard history is **enabled for function completeness** and may persist across sessions, but it must be bounded and controllable.

- Store text/URI clipboard entries under `$XDG_STATE_HOME/axiom-shell/clipboard-history` or equivalent user-local state.
- Default retention: persistent across sessions, capped to a finite number of entries (recommend 500) and a finite per-entry size (recommend 64 KiB). Binary/image support is not required for this task.
- Deduplicate repeated consecutive entries.
- Provide a visible **Clear clipboard history** action in the search surface and a helper command/service action that wipes the state file/database.
- Provide a disable path owned by Nix, e.g. `modules.desktop.quickshell.search.clipboard.enable = false`, that stops the watcher service and hides the provider. Disabling should not require deleting the whole shell.
- Rollback/privacy recovery: clear history, stop/disable the clipboard watcher, remove the state directory, or revert the implementation PR / switch to an older NixOS generation.

## Fallback behavior

- `Super+Space` should attempt to open Quickshell search first, preferably through a Quickshell IPC handler such as `toggleSearch`.
- If the IPC call fails, Quickshell is not running, or the panel cannot focus, the same binding must fall back to `fuzzel`.
- Keep a direct Fuzzel action inside declared actions, and preferably a secondary binding such as `Super+Shift+Space` to open Fuzzel directly.
- The dock `APP` button opens Quickshell search when the shell is alive; rollback changes it back to `fuzzel`.

## Verification plan

- Nix evaluation/build for Axiom to prove packages, services, and ownership remain valid: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Static diff checks: no upstream installer/downloaded scripts, no Rofi/DMS primary launcher path, Fuzzel still present, no arbitrary query-to-shell execution.
- QML smoke/static check using the available Quickshell command/environment; record if Wayland/layer-shell prevents headless execution.
- Provider helper smoke checks: list apps, launch/dry-run a known desktop id if safe, web URL encoding, calculator expression, emoji copy/list, clipboard list/copy/clear/disable.
- Hyprland config verification after binding changes, e.g. generated config plus `Hyprland --verify-config` where available.
- Runtime Axiom session checks: dock `APP`, `Super+Space`, fallback Fuzzel, app launch, declared actions, web search, calculator, emoji copy, clipboard persistence after restart, clear all, disable clipboard provider, notification panel regression check.

## Rollback plan

- Revert the implementation PR.
- Or minimally restore `APP` and `Super+Space` to `fuzzel`, disable/hide `SearchPanel`, and stop the clipboard watcher service.
- For clipboard-sensitive rollback: run clear action, remove `$XDG_STATE_HOME/axiom-shell/clipboard-history*`, and switch/reload the NixOS generation without the watcher.
- If only Quickshell fails, stop/restart `quickshell.service`; Hyprland bindings and direct Fuzzel remain available.

## Risks and unresolved questions

- Quickshell IPC/focus behavior may differ in the live session; fallback binding must be verified on Axiom.
- Desktop-entry launch details (`gtk-launch`, `dex`, `gio`, or helper implementation) need final package choice during implementation.
- Clipboard watcher implementation details should be kept small; avoid growing a background framework.
- Calculator and emoji datasets may require package choice tradeoffs, but both must remain local/offline.
