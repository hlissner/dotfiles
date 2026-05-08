# Test Report

## Summary

PASS. Axiom builds successfully from the worktree path with the new Isabel-first Quickshell desktop, and targeted checks confirm Axiom uses the local Quickshell product shell instead of DMS/Rofi as the primary desktop path.

## Why These Checks

- The user explicitly required `nix build` to pass, so the Axiom NixOS toplevel build is the primary gate.
- Targeted evals prove the product-shell ownership claims directly: Quickshell service, no DMS user service, Rofi disabled for Axiom, Thunar enabled, Quickshell config linked, and guide linked.
- Hyprland parser validation catches compositor syntax regressions that Nix evaluation alone does not catch.
- Regression searches confirm removed or demoted legacy paths are not still active in the primary Hyprland path.

## Commands

### Axiom Build

```sh
DOTFILES_HOME="/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop" \
  nix build --impure \
  "path:/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop#nixosConfigurations.axiom.config.system.build.toplevel"
```

Result: PASS.

Notes:

- This uses `path:` plus explicit `DOTFILES_HOME` because the shell environment had a stale `DOTFILES_HOME=/nix/store/...-source`; without overriding it, generated Home Manager paths pointed at the old flake source.
- Warnings were non-blocking pre-existing or upstream option warnings: specialArgs `pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, input method deprecation, and `system` rename warning.

### Targeted Desktop Eval

```sh
DOTFILES_HOME="/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop" \
  nix eval --impure --json --expr 'let c = (builtins.getFlake "path:/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop").nixosConfigurations.axiom.config; in { quickshellService = c.systemd.user.services.quickshell.serviceConfig.ExecStart; hasDmsService = c.systemd.user.services ? dms; rofiEnabled = c.modules.desktop.apps.rofi.enable; thunarEnabled = c.modules.desktop.apps.thunar.enable; quickshellConfigLinked = c.home.configFile ? "quickshell/axiom-shell"; guideLinked = c.home.configFile ? "axiom-desktop/guide.md"; quickshellPackages = map (p: p.name or (toString p)) c.environment.systemPackages; }'
```

Result: PASS.

Key evidence:

```json
{
  "guideLinked": true,
  "hasDmsService": false,
  "quickshellConfigLinked": true,
  "quickshellService": "/nix/store/...-axiom-quickshell/bin/quickshell --config axiom-shell",
  "rofiEnabled": false,
  "thunarEnabled": true
}
```

The package list also included `axiom-quickshell`, `fuzzel`, `wlogout`, `network-manager-applet`, `blueman`, `pavucontrol`, and `wf-recorder`.

### Hyprland Parser

```sh
hypr=$(DOTFILES_HOME="/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop" \
  nix eval --impure --raw --expr '(builtins.getFlake "path:/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop").nixosConfigurations.axiom.config.programs.hyprland.package')
full=$(DOTFILES_HOME="/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop" \
  nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop"; c = flake.nixosConfigurations.axiom.config; pkgs = flake.nixosConfigurations.axiom.pkgs; base = builtins.replaceStrings [ "source = ~/.config/hypr/hyprland.pre.conf\n" "source = ~/.config/hypr/hyprland.post.conf\n" ] [ "" "" ] (builtins.readFile /home/c1/dotfiles/.worktrees/dotfiles-quickshell-product-desktop/config/hypr/hyprland.conf); in pkgs.writeText "hyprland-full.conf" (c.home.configFile."hypr/hyprland.pre.conf".text + "\n" + base + "\n" + c.home.configFile."hypr/hyprland.post.conf".text)')
"$hypr/bin/Hyprland" --verify-config --config "$full"
```

Result: PASS with `config ok`.

### Regression Searches

```sh
grep '@rofi|dms ipc|dms run' config/hypr --include '*.conf'
grep 'systemd\.user\.services\.dms|dms run|dms ipc' modules --include '*.nix'
glob 'config/ncmpcpp/**'
```

Result: PASS.

- No primary Hyprland config references to `@rofi`, `dms ipc`, or `dms run`.
- No active module DMS service or DMS IPC references remain.
- `config/ncmpcpp/**` is absent.
- After the final review-prep polish, `Super+D` has only the existing screen drawing binding and the visible shell/guide include a `REC` screen recording control.

## Failures Fixed During Verification

- Initial `nix build .#...` used the stale `DOTFILES_HOME` environment and could not see the new guide file in the generated Home Manager source path.
- After switching to `path:` and explicit `DOTFILES_HOME`, build reached desktop entry validation and failed because the new guide launcher used shell quotes and `$HOME` in a `.desktop` `Exec` field.
- Fixed the launcher to use `/home/${config.user.name}/.config/axiom-desktop/guide.md`; the next build passed.

## Skipped / Deferred

- Live Quickshell rendering on Axiom hardware is not verified in this environment; it remains a post-build runtime check after deployment.
- Subjective visual preference is intentionally deferred to the user after the Isabel-aligned first pass is available.
