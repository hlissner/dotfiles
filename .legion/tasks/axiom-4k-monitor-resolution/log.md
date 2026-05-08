# Log

## 2026-05-08

- User reported the current desktop resolution is far too small for a 4K screen and asked for a reasonable resolution.
- Created `.worktrees/axiom-4k-monitor-resolution` on branch `legion/axiom-4k-monitor-resolution` from `origin/master`.
- Found Axiom had no host-specific monitor override, so Hyprland generated the generic fallback monitor rule from the module default.
- Live `hyprctl monitors -j` and `wlr-randr` could not run from this shell because no Hyprland/Wayland display is attached.
- Chose a connector-agnostic Axiom monitor rule: physical `3840x2160@60`, position `0x0`, fractional scale `1.5`.
- Relaxed the Hyprland monitor scale option to accept integer or float values.
- Validation passed: Axiom `nix build`, targeted monitor eval, and generated Hyprland `--verify-config` all succeeded. Targeted eval generated `monitor = ,3840x2160@60,0x0,1.500000`.
