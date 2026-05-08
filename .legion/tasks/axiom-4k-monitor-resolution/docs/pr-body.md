## Summary

- Set Axiom's Hyprland monitor default to physical `3840x2160@60` instead of generic `preferred`.
- Use fractional scale `1.5`, giving a reasonable 4K desktop density rather than tiny 1x UI or cramped 2x 1080p logical space.
- Allow Hyprland monitor scale options to be integer or float so fractional scaling is supported declaratively.

## Verification

- `DOTFILES_HOME="/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution" nix build --impure "path:/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution#nixosConfigurations.axiom.config.system.build.toplevel"`
- Targeted `nix eval` generated `monitor = ,3840x2160@60,0x0,1.500000`.
- Generated full Hyprland config passes `Hyprland --verify-config`.

## Notes

- The monitor rule is connector-agnostic because live DP/HDMI output detection was unavailable from this non-GUI shell.
