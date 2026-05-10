# Log: axiom-caelestia-keybind-fix

## 2026-05-10

- User reported a Hyprland parse error after the Caelestia migration: generated `hypr/custom/keybinds.conf` used `catchall` at top level, which Hyprland only allows inside submaps.
- Created focused hotfix task contract under `.legion/tasks/axiom-caelestia-keybind-fix/` and opened isolated worktree `.worktrees/axiom-caelestia-keybind-fix/` on branch `legion/axiom-caelestia-keybind-fix` from `origin/master`.
- Removed the invalid top-level `bindin = Super, catchall, global, caelestia:launcherInterrupt` line from `modules/desktop/hyprland.nix`, preserving the Caelestia launcher binding and explicit mouse interrupt bindings.
- User also reported checkerboard placeholder icons and pointed to Caelestia README icon context. Upstream shell README/Nix confirms `with-cli` and runtime deps/fonts but does not expose hicolor/adwaita/papirus/shared-mime fallback packages, so the local Caelestia integration now adds `hicolor-icon-theme`, `adwaita-icon-theme`, `papirus-icon-theme`, `shared-mime-info`, and `xdg-utils` to Linux user packages.
- Verification passed: generated keybind eval contains no `catchall`, Axiom evaluated user packages include the Caelestia shell/CLI and icon/MIME fallback packages, assembled Axiom Hyprland config passes `Hyprland --verify-config`, `git diff --check` passed, and Axiom toplevel build passed.
- Readiness review returned PASS with no blocking findings. Security lens was considered for global keybindings; the change removes a catchall binding and adds no new privileged action or user-input execution path.
- Generated implementation-mode `docs/report-walkthrough.md` and `docs/pr-body.md` from the existing implementation, validation, and review evidence, then updated them for the icon/MIME package fix.
- Completed Legion wiki writeback: added `wiki/tasks/axiom-caelestia-keybind-fix.md` and extended the Caelestia integration pattern with icon/MIME fallback package exposure plus assembled Hyprland parser validation for generated keybind/rule changes.
