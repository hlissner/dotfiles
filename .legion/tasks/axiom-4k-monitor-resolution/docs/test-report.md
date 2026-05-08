# Test Report

## Summary

PASS. Axiom now evaluates a connector-agnostic 4K Hyprland monitor rule and the NixOS toplevel build still succeeds.

## Commands

### Axiom Build

```sh
DOTFILES_HOME="/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution" \
  nix build --impure \
  "path:/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution#nixosConfigurations.axiom.config.system.build.toplevel"
```

Result: PASS.

### Monitor Eval

```sh
DOTFILES_HOME="/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution" \
  nix eval --impure --json --expr 'let c = (builtins.getFlake "path:/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution").nixosConfigurations.axiom.config; in { monitors = c.modules.desktop.hyprland.monitors; preConfig = c.home.configFile."hypr/hyprland.pre.conf".text; }'
```

Result: PASS.

Key generated monitor rule:

```hyprlang
monitor = ,3840x2160@60,0x0,1.500000
```

### Hyprland Parser

```sh
hypr=$(DOTFILES_HOME="/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution" \
  nix eval --impure --raw --expr '(builtins.getFlake "path:/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution").nixosConfigurations.axiom.config.programs.hyprland.package')
full=$(DOTFILES_HOME="/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution" \
  nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution"; c = flake.nixosConfigurations.axiom.config; pkgs = flake.nixosConfigurations.axiom.pkgs; base = builtins.replaceStrings [ "source = ~/.config/hypr/hyprland.pre.conf\n" "source = ~/.config/hypr/hyprland.post.conf\n" ] [ "" "" ] (builtins.readFile /home/c1/dotfiles/.worktrees/axiom-4k-monitor-resolution/config/hypr/hyprland.conf); in pkgs.writeText "hyprland-full.conf" (c.home.configFile."hypr/hyprland.pre.conf".text + "\n" + base + "\n" + c.home.configFile."hypr/hyprland.post.conf".text)')
"$hypr/bin/Hyprland" --verify-config --config "$full"
```

Result: PASS with `config ok`.

## Notes

- Live monitor introspection with `hyprctl monitors -j` and `wlr-randr` was not available from this shell because no Hyprland/Wayland display is attached.
- The rule intentionally omits a connector name so Axiom can apply the 4K mode without guessing whether the panel is connected as DP or HDMI.
