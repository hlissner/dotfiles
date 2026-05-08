# Research Notes

## Problem Restatement

The current Wayland state is technically Hyprland + Quickshell-capable, but it does not deliver the requested desktop product. Axiom still presents an autumnal wallpaper plus Rofi/shortcut-first workflow, while the requested target is Isabel-like: visible shell, polished Hyprland behavior, GUI entry points, and a gentle shortcut onboarding path.

## Relevant Code / Entry Points

- `hosts/axiom/default.nix` - enables `modules.theme.active = "autumnal"`, `desktop.hyprland.enable = true`, `desktop.apps.rofi.enable = true`, Zen, Vesktop, Steam, foot, mpv, and input modules.
- `modules/desktop/hyprland.nix` - owns UWSM/greetd, session bootstrap, Hyprland generated pre/post config, DMS/Quickshell default enablement, app window rules, and DMS launcher entries.
- `modules/desktop/quickshell.nix` - currently packages `pkgs.unstable.dms`, `quickshell`, `matugen`, and starts `dms run` as `dms.service`; it does not provide a local Quickshell UI.
- `modules/desktop/apps/rofi.nix` - installs Rofi and most GUI-ish launchers; this conflicts with the new requirement if treated as the primary shell/control entry.
- `config/hypr/hyprland.conf` - contains the active common Hyprland defaults and a shortcut-heavy modal workflow inherited from the hlissner-style setup.
- `modules/themes/autumnal/hyprland.nix` - forces a sharper hlissner/autumn look with zero gaps, zero rounding, DMS/Quickshell layer rules, and autumnal wallpaper integration.
- `config/ncmpcpp/` - stale config payload still present locally; hlissner upstream snapshot at `1b4383a` no longer has it.

## Existing Conventions

- NixOS modules are under `modules/**`; checked-in runtime config payloads are under `config/**` and linked through Home Manager `home.configFile`.
- Linux desktop code must stay out of Darwin imports, per `.legion/wiki/decisions.md`.
- Previous tasks validated Hyprland by combining generated pre config, checked-in base config, generated post/theme config, then running `Hyprland --verify-config`.
- Legion workflow requires this implementation to stay in the PR worktree and later go through verify/review/walkthrough/wiki.

## Historical Decisions

- `.legion/tasks/dotfiles-wayland-product-overhaul/docs/rfc.md` approved Hyprland + UWSM + DMS/Quickshell and removal of old desktop compatibility.
- `.legion/wiki/decisions.md` currently states the Linux workstation direction as Hyprland + UWSM + DMS/Quickshell, but the current user requirement narrows that to Isabel-first Quickshell product shell, not DMS/Rofi-first UX.
- Runtime followups established that `hyprland-uwsm.desktop` is the evaluated session entry and that foreground `hyprlock --immediate` must not block visible shell startup.

## Upstream Findings

- hlissner upstream `1b4383a` is useful for cleanup discipline, UWSM, Steam/workstation tuning, and removing stale desktop paths. It is not the desktop product target.
- Isabel upstream `b9c5f08` uses Quickshell enablement, polished Hyprland defaults, GUI app bindings, declarative monitor/workspace behavior, and a visible screenshot with a persistent side shell/dock/status surface.
- Isabel's current repository does not expose a large reusable Quickshell QML tree in the inspected snapshot; therefore a local shell should be implemented instead of copying a hidden/private framework.

## Constraints & Non-Goals

- The user explicitly allows discarding hlissner desktop configuration, including Rofi, and rejects backward compatibility as a constraint.
- The implementation must pass actual `nix build` for Axiom before delivery.
- No full Isabel `garden` framework import.
- No Secure Boot, dual boot, or Darwin desktop work in this task.

## Risks & Pitfalls

- Quickshell QML APIs may differ from assumptions; keep the shell simple enough to compile and run without complex DBus models.
- Removing Rofi entirely can break existing `hey @rofi` keybindings if they are not replaced; keybindings must point to Quickshell-facing GUI entries or direct apps.
- DMS may conflict with a local Quickshell shell if both own shell surfaces; choose one default shell owner.
- The `nix build` requirement may expose unrelated build failures; in-scope failures must be fixed and unrelated failures documented only if genuinely outside scope.

## Unknowns

- [ ] Exact runtime Quickshell rendering on Axiom hardware can only be fully confirmed on the physical desktop after build/deploy.
- [ ] Whether future user preference wants the side shell exactly like Isabel's screenshot or more macOS top-bar/dock-like; first pass should choose the Isabel screenshot baseline.

## References

- Plan: `.legion/tasks/dotfiles-quickshell-product-desktop/plan.md`
- Isabel reference: `/tmp/opencode/isabelroses-dotfiles`, commit `b9c5f08`
- hlissner reference: `/tmp/opencode/hlissner-dotfiles`, commit `1b4383a`
- Prior task: `.legion/tasks/dotfiles-wayland-product-overhaul/`
- Current truth: `.legion/wiki/decisions.md`
