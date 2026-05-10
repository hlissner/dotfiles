# Axiom Caelestia Wallpaper And Launcher Fix Log

## 2026-05-10

- Started via `legion-workflow` after a live Axiom Caelestia regression report.
- Current boot evidence: `caelestia-shell.service` repeatedly exits with status `255/EXCEPTION` after Wayland fatal errors around lock events, then restarts under systemd.
- Current boot evidence: `quickshell list --all` showed an unmanaged Caelestia shell instance and a systemd-managed instance with the same shell ID.
- Current boot evidence: `hyprctl layers -j` showed the old `swaybg` wallpaper layer plus duplicate `caelestia-background` surfaces.
- Current boot evidence: `systemctl --user show caelestia-shell.service -p Environment -p ExecStart` showed a minimal PATH containing only coreutils/findutils/grep/sed/systemd, while Caelestia launcher uses `app2unit` and helper UI paths use tools such as `lsblk`.
- Current boot evidence: Caelestia logs repeatedly reported `Process failed to start ... QList("lsblk", ...)`, matching the minimal PATH problem.
- Current boot evidence: Caelestia logs reported missing `/home/c1/.local/state/caelestia/wallpaper/path.txt`, while Hyprland still started `swaybg -o * -i /home/c1/the-great-sage.jpg -m stretch`.
- User clarified that the desired final wallpaper owner is Caelestia, not `swaybg`.
- Opened worktree `.worktrees/axiom-caelestia-wallpaper-launcher-fix` from `origin/master` at `3db9be8d34e3ce43ebb03a9aaf9fc132e4358c22` on branch `legion/axiom-caelestia-wallpaper-launcher-fix-runtime`.
- RFC design gate passed. Implemented Caelestia wallpaper ownership for Axiom, service startup seeding for missing wallpaper state, service PATH/`--no-duplicate`, systemd-owned shell restart keybinds, and hyprlock-based ordinary lock paths.
- Verification passed: targeted Nix eval confirmed key generated values and `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --impure` completed successfully.
- Change review passed with security lens for lock/session behavior. No blocking findings.
- Walkthrough, PR body, and wiki writeback completed.
