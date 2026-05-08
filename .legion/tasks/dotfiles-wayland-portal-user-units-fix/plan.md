# Dotfiles Wayland Portal User Units Fix

## Goal

Fix the `axiom` build failure where user systemd unit generation attempts to link `xdg-desktop-portal-gtk.service` twice.

## Scope

- Adjust Hyprland portal configuration only.
- Preserve the intended portal product surface: Hyprland portal plus GTK fallback.
- Verify actual `axiom` toplevel build, not only dry-run/evaluation.

## Non-goals

- No broader Wayland stack redesign.
- No changes to browser, Discord, Steam, Wi-Fi, Bluetooth, or Darwin behavior.
