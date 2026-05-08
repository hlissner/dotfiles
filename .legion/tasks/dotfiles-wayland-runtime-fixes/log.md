# Dotfiles Wayland Runtime Fixes Log

## 2026-05-08

- Started runtime regression fix from latest `origin/master` after PR #4 portal unit fix merged at `eac4e00d`.
- User-reported symptoms: missing Hyprland desktop entry during login and no network on `axiom`.
- Scope is intentionally narrow: Hyprland/UWSM session entry wiring and `axiom` NetworkManager+iwd+resolved startup ownership only.
- Created worktree `.worktrees/dotfiles-wayland-runtime-fixes/` on branch `legion/dotfiles-wayland-runtime-fixes` tracking `origin/master`.
- Confirmed the evaluated `axiom` session package provides `hyprland-uwsm.desktop`, while greetd was invoking nonexistent `hyprland.desktop`.
- Confirmed `axiom` enabled legacy `dhcpcd` through `networking.interfaces.enp14s0.useDHCP = true` alongside NetworkManager/iwd.
- Updated greetd to start `hyprland-uwsm.desktop`, disabled iwd's built-in network configuration under NetworkManager, and moved `enp14s0` DHCP/autoconnect ownership into a NetworkManager ensure profile.
- Verification passed: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` succeeded.
- Targeted eval passed: `hyprland-uwsm.desktop` exists, `hyprland.desktop` does not, greetd references `hyprland-uwsm.desktop`, NetworkManager uses iwd/resolved, iwd network configuration is disabled, and `dhcpcd` is disabled with no service.
- Diff hygiene passed with `git diff --check`.
- Readiness review passed with no blocking findings. Security lens was applied because login/session startup and network service ownership changed; no security blocker was found.
- Generated reviewer walkthrough and PR body from existing verification and review evidence.
- Completed Legion wiki writeback with task summary, current decisions, validation pattern, and wiki log updates.
