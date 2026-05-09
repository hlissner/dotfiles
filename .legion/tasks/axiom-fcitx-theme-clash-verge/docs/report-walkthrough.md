# Report Walkthrough

Mode: implementation.

## Summary

- Fixes Fcitx5 Catppuccin theme precedence on `axiom` by managing the user-level `fcitx5/conf/classicui.conf` theme selection in addition to the existing system-level config.
- Adds reusable `modules.desktop.apps.clash-verge` with default package `pkgs.clash-verge-rev`.
- Enables Clash Verge only for `axiom`.

## Files Changed

- `modules/desktop/input/fcitx5.nix`: writes force-managed user-level classic UI theme config when the Fcitx5 Catppuccin theme is enabled.
- `modules/desktop/apps/clash-verge.nix`: defines the new reusable app module with `enable` and `package` options.
- `hosts/axiom/default.nix`: enables `modules.desktop.apps.clash-verge`.
- `.legion/tasks/axiom-fcitx-theme-clash-verge/docs/test-report.md`: records focused eval evidence.
- `.legion/tasks/axiom-fcitx-theme-clash-verge/docs/review-change.md`: records readiness review.

## Verification

Evidence is in `docs/test-report.md`.

- User-level Fcitx classic UI config evaluates to `Theme=catppuccin-mocha-mauve`.
- User-level Fcitx classic UI config evaluates with `force = true` to replace stale UI theme files.
- System-level Fcitx classic UI config still evaluates to the Catppuccin Mocha Mauve theme.
- Clash Verge module is enabled on `axiom`.
- `clash-verge-rev` is present in final `users.users.c1.packages`.
- `axiom` system toplevel derivation evaluates successfully.

## Review

Evidence is in `docs/review-change.md`.

- PASS with no blocking findings.
- No security-sensitive profile, credential, routing, auth, or secret handling changes.
- Residual risk is limited to replacing non-dictionary Fcitx classic UI preferences in the managed `classicui.conf` file.

## Out Of Scope

- Clash profiles, subscriptions, credentials, daemon/service routing, and proxy policy.
- Rime schema, Rime dictionaries, and private Fcitx/Rime user data.
- Global desktop theme changes.
