# Dotfiles Wayland Visible Shell Log

## 2026-05-08

- Started visible-shell runtime fix from latest `origin/master` after PR #6 merged at `d8fb55d6`.
- User-reported symptoms: networking now works; Hyprland shows a cursor, but the desktop is otherwise black.
- Scope is intentionally narrow: Hyprland session bootstrap, DMS/Quickshell shell startup, and wallpaper/background visibility.
- Product goal remains the original direction: hlissner-style modular architecture fused with Isabel-style usable Wayland product surface.
- Created worktree `.worktrees/dotfiles-wayland-visible-shell/` on branch `legion/dotfiles-wayland-visible-shell` tracking `origin/master`.
- Confirmed Hyprland generated config runs `exec-once = hey hook startup`; startup hooks are sequentially ordered by filename.
- Found `startup."05-loginscreen"` launching foreground `hyprlock --immediate` before starting `hyprland-session.target` and before the `10-wallpaper` hook. This can produce a live compositor/cursor while blocking DMS/Quickshell and wallpaper startup.
- Confirmed DMS service is enabled and wanted by `hyprland-session.target`/`graphical-session.target`, and the autumnal wallpaper exists in the evaluated theme path.
- Replaced the startup lock-screen gate with a `05-session` bootstrap that imports the compositor environment and starts `hyprland-session.target`; manual lock remains available through existing Hyprland keybindings.
- Verification passed: actual `axiom` toplevel build succeeded.
- Hyprland parser validation passed against the combined generated/base/theme config.
- Targeted eval passed: startup hooks are `05-session` and `10-wallpaper`, `05-session` starts `hyprland-session.target`, no startup hook launches `hyprlock --immediate`, DMS remains wanted by the session targets, and wallpaper starts through `swaybg`.
- Diff hygiene passed with `git diff --check`.
- Readiness review passed with no blocking findings. Security lens was applied because lock-screen/session startup changed; the removed pseudo-login behavior is an accepted tradeoff for unblocking shell/wallpaper startup, with boot-time physical access protection left as a possible follow-up.
- Wrote implementation-mode walkthrough and PR body from existing test and review evidence.
- Wrote Legion wiki summary and durable decisions/patterns for visible-shell startup bootstrap: start `hyprland-session.target` before shell/wallpaper hooks and do not gate DMS/Quickshell behind foreground startup `hyprlock --immediate`.
