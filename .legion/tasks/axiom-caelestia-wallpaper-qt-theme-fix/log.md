# Axiom Caelestia Wallpaper Qt Theme Fix Log

## 2026-05-10

- Started via `legion-workflow` follow-up after PR #25 fixed wallpaper ownership and Caelestia service boundaries but live validation still showed a black wallpaper and icon color blocks.
- Current live evidence from prior handoff: Caelestia is the only wallpaper owner, no `swaybg` process is active, and one systemd-managed quickshell instance remains.
- Current live evidence from prior handoff: Caelestia logs reject `/home/c1/the-great-sage.jpg` with `QImageIOHandler: Rejecting image as it exceeds the current allocation limit of 256 megabytes`, followed by null-image cache/analyser messages.
- User provided upstream issue reference `https://github.com/caelestia-dots/shell/issues/1282` for the launcher icon block problem.
- Fetched issue #1282 with `gh issue view 1282 --repo caelestia-dots/shell --comments`; contributor guidance says replacing `QT_QPA_PLATFORMTHEME` from `qtengine` to `qt6ct` or `qt5ct`, then restarting Hyprland, fixed the symptom. A follow-up comment says the working edit was in `~/.config/hypr/hyprland/env.conf` and references upstream commit `caelestia-dots/caelestia@cf94e7f5e22133dfb6a190f634d41fe6800c5c7c`.
- Repository search found no active `QT_QPA_PLATFORMTHEME`, `qtengine`, `qt6ct`, or `qt5ct` setting in Nix files except a commented `libsForQt5.qt5ct` line in the Nvidia module; the repo-owned generated Hyprland env currently lacks the Qt platform theme variable.
- Entered git worktree envelope from `origin/master` at `e17699acc8edffc9accb47c1046d7805a4d12ecd`; worktree `.worktrees/axiom-caelestia-wallpaper-qt-theme-fix`, branch `legion/axiom-caelestia-wallpaper-qt-theme-runtime`.
- Inspected the source wallpaper with ImageMagick: `/home/c1/the-great-sage.jpg` is `11846x5733`, which is about `259 MiB` at 4 bytes per pixel and explains why it barely exceeds Qt's observed `256 MB` allocation limit.
- Drafted RFC recommending a runtime-generated 3840x2160-bound Caelestia wallpaper derivative plus repo-owned `QT_QPA_PLATFORMTHEME=qt6ct` in Hyprland/UWSM env.
- RFC review passed with no blocking findings. Implementation can proceed with the runtime derivative and `qt6ct` session environment plan.
- Implemented Caelestia seed logic that generates `/home/c1/.local/state/caelestia/wallpaper/generated.jpg` from the configured wallpaper with ImageMagick, bounded to `3840x2160`, and rewrites `path.txt` only when the current state is missing, empty, or still points at the oversized canonical source.
- Implemented `QT_QPA_PLATFORMTHEME=qt6ct` in the Caelestia systemd service environment, generated Hyprland env, generated UWSM env, global Hyprland session variables, and the systemd user environment import hook. Added `pkgs.unstable.qt6Packages.qt6ct` to Caelestia user packages.
- Local implementation checks passed: generated `hypr/custom/env.conf` contains `env = QT_QPA_PLATFORMTHEME,qt6ct`; generated `uwsm/env` exports `QT_QPA_PLATFORMTHEME=qt6ct`; `caelestia-shell.service` environment contains `QT_QPA_PLATFORMTHEME=qt6ct`; the startup import hook imports `QT_QPA_PLATFORMTHEME`.
- Verification passed: targeted Nix eval confirmed generated Qt/theme/service values and `qt6ct` package inclusion; `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure` completed successfully; ImageMagick smoke test converted `/home/c1/the-great-sage.jpg` to a `3840x1858` `757392B` derivative using the same transform as the service script.
- Change review passed with security lens for user-session environment and runtime state generation. No blocking findings. Non-blocking note: `0700` state directory and atomic `path.txt` writes could harden the script further, but current behavior is not a privilege-boundary issue because it runs as the user.
- Walkthrough and PR body generated from existing RFC, verification, and review evidence.
- Wiki writeback completed with a task summary plus updated Caelestia decisions, patterns, maintenance, index, and wiki log entries.
