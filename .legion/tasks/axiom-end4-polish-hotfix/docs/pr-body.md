## Summary

- Fix end4 `ii` launcher/polish integration by routing `Super+Space` through the start-menu IPC path, adding a `shell alive` fallback probe, and tightening launcher/overview keyboard focus while keeping end4 as the active shell.
- Add Nix-owned Quickshell runtime PATH coverage plus cache/state/wallpaper path fixes for network/Bluetooth helpers, image/preview tooling, preset wallpaper selection, and matugen theme generation.
- Enable and pin the end4 dock by default, migrate existing config once, and anchor the dock to the far-left edge.

## Validation

- PASS: `git diff --check`
- PASS: no remaining `TEST_ALIVE` references in checked repo/generated/store surfaces.
- PASS: Nix eval confirms generated `Super+Space` binding uses `startMenu toggle || search toggle || fuzzel`.
- PASS: Nix eval confirms Quickshell service PATH includes relevant runtime tools for network/Bluetooth, image preview, wallpaper, theme generation, screenshots, and Hyprland helpers.
- PASS: Nix eval confirms Quickshell still starts `--config ii` and Home Manager owns `.config/quickshell/ii` from the repo source.
- PASS: static checks cover `shell alive`, `startMenu toggle`, wallpaper selector/preset/matugen integration, dock defaults/migration, and left-edge dock anchors.
- PASS: `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link`

## Risk/Notes

- Live graphical behavior remains the main residual risk because validation ran from a non-graphical shell.
- Post-deployment smoke test should press `Super+Space` and type, inspect network/Bluetooth status icons, preview a screenshot/image, apply an end4 preset wallpaper and confirm theme regeneration, and confirm the dock is pinned on the far-left edge.
- `shell alive` is a liveness probe for fallback gating; feature-specific behavior still depends on the running Quickshell session.
- Dock migration intentionally updates persisted Quickshell config once and records `end4PolishDockMigrated` to avoid repeatedly overriding later user choices.

## Legion Evidence

- Plan: `.legion/tasks/axiom-end4-polish-hotfix/plan.md`
- Implementation log: `.legion/tasks/axiom-end4-polish-hotfix/log.md`
- Validation report: `.legion/tasks/axiom-end4-polish-hotfix/docs/test-report.md`
- Review report: `.legion/tasks/axiom-end4-polish-hotfix/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-end4-polish-hotfix/docs/report-walkthrough.md`
