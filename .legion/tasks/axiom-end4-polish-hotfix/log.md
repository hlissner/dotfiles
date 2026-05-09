# Axiom End4 Polish Hotfix Log

## 2026-05-10

- User requested Legion workflow for three end4 follow-up issues: `Super+Space` shows a black non-responsive box, network/Bluetooth icons render as black-white checkerboards, and `Ctrl+Super+T` image preview renders checkerboards.
- Entry used `brainstorm` because no existing task id/path was specified.
- User confirmed the task contract: treat the three issues as one low-risk hotfix, keep end4 `ii` as the active path, do not roll back or redesign broad UI surfaces.
- Materialized task contract under `.legion/tasks/axiom-end4-polish-hotfix/` and prepared for mandatory isolated worktree implementation.
- User added that the wallpaper system is also broken: end4 preset wallpapers cannot be selected and the corresponding theme color switch is not visible. Folded this into the current hotfix because it is the same `Ctrl+Super+T` wallpaper selector/theme path.
- User requested enabling the end4 dock and placing it on the far left. Folded this into the hotfix as a minimal end4 default config change, not a dock redesign.
- Opened isolated worktree `.worktrees/axiom-end4-polish-hotfix/` on branch `legion/axiom-end4-polish-hotfix` from `origin/master`.
- Found `Super+Space` was using the generic `search` IPC while Waffle defines both start-menu and task-view handlers under that target. Split the start-menu IPC to `startMenu`, changed the generated host binding to try `startMenu toggle` before `search toggle`, and made both ii overview and Waffle start menu request exclusive keyboard focus while open.
- Found live Quickshell service logs showing QML processes could not start `hyprctl` and `cliphist`; this means systemd-started Quickshell did not have the runtime tool PATH needed by end4 helpers. Added an explicit Quickshell service PATH covering Hyprland tools, cliphist, wl-clipboard, ImageMagick, matugen, ffmpeg, swappy, network/Bluetooth tools, and related helpers.
- Found imported Hyprland fallback binds used `qs ipc call TEST_ALIVE` without an IPC function, so the probe always failed. Added a no-op `shell alive` IPC and replaced fallback probes, preventing `Ctrl+Super+T` from launching `switchwall.sh` when the Quickshell wallpaper selector is alive.
- Moved Quickshell temporary image, screenshot, and cliphist decode paths from `/tmp/quickshell` to the user cache boundary; added End4 preset wallpaper assets as the wallpaper selector default/quick directory.
- Ensured `switchwall.sh` creates state/generated directories before matugen and material-color generation, so wallpaper selection has a valid theme output path.
- Enabled the end4 dock by default, added a one-time Axiom config migration for existing user config, pinned it on startup, and aligned the bottom dock to the far left edge.
- Local implementation checks passed: generated custom keybind eval includes `startMenu toggle || search toggle`, Quickshell service path eval includes runtime tools, and full Axiom system toplevel build completed.
- Verification passed and was recorded in `docs/test-report.md`: `git diff --check`, focused `TEST_ALIVE`/IPC/service PATH/wallpaper/dock static checks, generated Hyprland and Quickshell Nix evals, and `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` all passed. Live UI behavior remains a post-deployment smoke-test risk due to the non-graphical tool shell.
- Readiness review passed in `docs/review-change.md`; no blocking scope, security, or verification findings were found.
- Generated reviewer-facing `docs/report-walkthrough.md` and `docs/pr-body.md`.
- Completed Legion wiki writeback with task summary plus end4 decision/pattern/maintenance updates.
