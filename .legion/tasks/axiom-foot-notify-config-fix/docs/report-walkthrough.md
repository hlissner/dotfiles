# Walkthrough: Axiom Foot Notify Config Fix

> Mode: implementation
> Task: `.legion/tasks/axiom-foot-notify-config-fix/`
> Evidence only: this summarizes existing task evidence and does not add new validation.

## Reviewer Summary

This fixes Foot failing before terminal startup on Axiom. The repository global Foot config contains `[main].notify`, and Foot 1.25.0 rejects that key as an invalid option. Because `modules/desktop/term/foot.nix` links `config/foot/foot.ini` as `foot/foot.global.ini`, removing the unsupported key directly addresses the live error path reported by the user.

## What Changed

- `config/foot/foot.ini` no longer emits `[main].notify`.
- No terminal default, launcher, Hyprland, shell, or notification stack behavior was otherwise changed.

## Evidence

- FAIL before patch: `foot --check-config --config config/foot/foot.ini` reproduced `[main].notify` as an invalid option.
- PASS after patch: `foot --check-config --config config/foot/foot.ini`.
- PASS: Nix-evaluated `foot/foot.global.ini` source path validates with Foot.
- PASS: `git diff --check`.
- PASS: full Axiom NixOS toplevel build.
- PASS: change review, no blockers.

## Residual Risk

- Any old terminal-notification behavior tied to the unsupported key is removed for now.
- The fixed generation still needs live deployment, followed by opening Foot from the normal terminal path to confirm the runtime abort is gone.
