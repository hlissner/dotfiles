## Summary

- Align Axiom Fcitx5 with the current shell/desktop pink accent by selecting `catppuccin-mocha-pink`.
- Preserve Rime, Pinyin/Chinese addons, and the existing force-managed `classicui.conf` behavior.
- Keep the change scoped to Axiom host theme selection only.

## Validation

- PASS: focused `nix eval` for generated Fcitx5 theme/user config/addons
- PASS: focused `nix eval` for Axiom Fcitx5 options
- PASS: assembled Hyprland `--verify-config` returned `config ok`
- PASS: `nix build --impure '.#nixosConfigurations.axiom.config.system.build.toplevel' --no-link`
- PASS: `git diff --check`

## Notes

- Live color rendering still needs Axiom deployment and Fcitx5/session restart.
