# Axiom Fcitx5 Shell Theme Alignment

## Task Identity

- Name: Axiom Fcitx5 Shell Theme Alignment
- Task ID: `axiom-fcitx5-shell-theme-alignment`
- Trigger: user asked for the Fcitx5 theme colors to match the shell theme after the Caelestia input hotfix.
- Risk: low

## Goal

Align Axiom's Fcitx5 classic UI theme accent with the current shell/desktop visual accent while preserving the existing input method engines and user-level Fcitx5 theme management.

## Problem

Axiom currently enables the Autumnal desktop theme, which uses Graphite pink GTK styling and pink Hyprland/Caelestia-adjacent accent colors. Fcitx5 is still configured as `catppuccin-mocha-mauve`, so the input candidate UI can visually diverge from the active shell/desktop theme. The existing Fcitx5 module already supports Catppuccin flavor/accent selection and force-manages only `fcitx5/conf/classicui.conf`, so this should be a focused host-level alignment.

## Acceptance

- [ ] Axiom evaluates Fcitx5 classic UI theme as `catppuccin-mocha-pink`.
- [ ] The force-managed user-level `fcitx5/conf/classicui.conf` emits `Theme=catppuccin-mocha-pink`.
- [ ] The system-level Fcitx5 classic UI setting remains consistent with the user-level file.
- [ ] Existing Fcitx5 engines remain enabled: Rime and Pinyin/Chinese addons stay configured.
- [ ] The change stays scoped to Fcitx5 theme alignment and does not touch Rime schemas, dictionaries, keyboard layout, Caelestia shell settings, Hyprland keybinds, or unrelated apps.
- [ ] Focused Nix evaluation and the strongest affordable build/static check prove the generated config shape.

## Assumptions / Constraints / Risks

- **Assumption**: Axiom's current shell/desktop accent is pink because Autumnal uses `Graphite-pink-Dark` and Hyprland active border includes Catppuccin pink.
- **Assumption**: Catppuccin Fcitx5's `pink` accent is the closest existing packaged match; no custom Fcitx5 theme derivation is needed.
- **Constraint**: Preserve the previous Fcitx5 theme precedence fix that force-manages only `fcitx5/conf/classicui.conf`.
- **Constraint**: Do not modify Rime dictionaries, schemas, or private input data.
- **Constraint**: Do not broaden this into Caelestia shell theming or GTK/Qt theme changes.
- **Risk**: Static evaluation proves generated theme selection, but live Fcitx5 UI color rendering still needs a session restart or Fcitx5 restart.

## Scope

- `hosts/axiom/default.nix`
- `.legion/tasks/axiom-fcitx5-shell-theme-alignment/**`
- `.legion/wiki/**` closing writeback

## Non-Goals

- Do not redesign the Fcitx5 module API.
- Do not create a custom Fcitx5 theme package.
- Do not change the Axiom keyboard layout or input engine list.
- Do not modify Caelestia shell JSON, Hyprland shortcuts, or wallpaper behavior.

## Design Summary

- Keep Axiom on Catppuccin Mocha for Fcitx5.
- Set Axiom's Fcitx5 accent to `pink`, matching the active shell/desktop accent.
- Validate both the NixOS Fcitx5 setting and the force-managed user-level classic UI file.

## Phases

1. **Brainstorm** - Materialize a scoped low-risk task contract.
2. **Engineer** - Patch Axiom Fcitx5 accent selection in the isolated worktree.
3. **Verify Change** - Run focused Nix eval/build checks and record evidence.
4. **Review Change** - Read-only readiness review for scope and correctness.
5. **Report Walkthrough** - Generate reviewer-facing summary and PR body.
6. **Legion Wiki** - Write reusable task summary and maintenance note.

---

*Created: 2026-05-11 | Last updated: 2026-05-11*
