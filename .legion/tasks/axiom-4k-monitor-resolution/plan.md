# Axiom 4K Monitor Resolution

## Goal

Set Axiom's default Hyprland monitor mode to a reasonable 4K desktop instead of relying on generic `preferred` output handling.

## Acceptance

- Axiom generates a Hyprland monitor rule for `3840x2160@60`.
- Axiom uses fractional scale `1.5` so the 4K panel keeps usable desktop space without tiny UI.
- Axiom NixOS build/eval and generated Hyprland config validation pass.

## Scope

- `hosts/axiom/default.nix`
- `modules/desktop/hyprland.nix` monitor scale type
- Verification evidence for Axiom monitor config
