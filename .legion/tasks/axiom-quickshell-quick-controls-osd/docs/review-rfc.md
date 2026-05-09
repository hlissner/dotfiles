# Review RFC: Axiom Quickshell Quick Controls and OSD

## Status

PASS

## Blocking issues

None.

The RFC is bounded enough to enter implementation: it rejects deep DBus/control-center parity, preserves explicit external fallbacks, keeps OSD rollback paths, limits actions to fixed helper verbs/static argv, and includes credible static/headless plus live-session verification for the parts that cannot be proven without Wayland/layer-shell runtime.

## Non-blocking recommendations for implementer

- Keep DBus/CLI control depth shallow: if `nmcli`/`bluetoothctl` toggles are not deterministic in the target session, display status plus fallback buttons rather than expanding into onboarding/pairing/device management.
- Treat OSD wrappers as compatibility wrappers, not rewrites: state changes must happen even when Quickshell IPC fails, and fallback `notify-send`/`hey .osd` behavior must remain testable.
- Preserve media-key behavior before adding OSD polish: direct `playerctl` semantics for play/pause/next/previous/seek should survive wrapper and IPC failures.
- Avoid widening command execution while refactoring current `sh -lc` static commands; new helper actions should stay fixed-verb/static-argv and never accept query-derived shell text.
- Verify Stage 1/2 regressions explicitly in the live checklist: side dock, notification panel, search panel, Fuzzel fallback, and one-`PanelWindow`-per-`Variants` composition.
- Record any headless verification gaps as runtime checklist items instead of claiming Quickshell/layer-shell behavior was proven statically.
