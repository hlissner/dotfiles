# Dotfiles Wayland Runtime Follow-up Log

## 2026-05-08

- Started follow-up runtime fix from latest `origin/master` after PR #5 merged at `01ea7e83`.
- User-reported symptoms: Hyprland reports deprecated `windowrulev2` plus syntax errors, and `axiom` still appears to have no network.
- Scope is intentionally narrow: generated Hyprland rule syntax and `axiom` NetworkManager+iwd+resolved startup/default connection behavior.
- Created worktree `.worktrees/dotfiles-wayland-runtime-followup/` on branch `legion/dotfiles-wayland-runtime-followup` tracking `origin/master`.
- Confirmed Hyprland 0.53.3 treats `windowrulev2` as a hard parse error and uses v3 `windowrule = match:..., effect ...` syntax.
- Found old rule syntax in both generated `hypr/hyprland.pre.conf` output and checked-in `config/hypr/hyprland.conf`, including legacy layer rule spellings.
- Converted window/layer rules to Hyprland 0.53 rule syntax and removed NetworkManager `no-auto-default=*` so NetworkManager can create fallback default connections when declarative profiles are missing or stale.
- Hyprland full-config verification also showed removed `gestures:workspace_swipe`; removed that obsolete no-op setting because workspace swipe is already disabled by default in the evaluated config set.
- Verification passed: actual `axiom` toplevel build succeeded.
- Hyprland parser validation passed with `Hyprland --verify-config` against the combined generated/base/theme config.
- Targeted eval passed: Hyprland version is 0.53.3, `windowrulev2` is absent, generated config uses new `windowrule`, NetworkManager uses iwd/resolved, `no-auto-default` is absent, iwd network configuration is disabled, and `dhcpcd` remains disabled/absent.
- Diff hygiene passed with `git diff --check`.
- Readiness review passed with no blocking findings. Security lens was applied for session config parsing and network service defaults; no security blocker was found.
- Generated reviewer walkthrough and PR body from existing verification and review evidence.
- Completed Legion wiki writeback with task summary, current decisions, validation pattern, and wiki log updates.
