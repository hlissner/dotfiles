# Test Report

## Summary

PASS. Focused Nix evaluation confirms that `axiom` now generates both system and force-managed user-level Fcitx5 `classicui.conf` theme selection, enables the reusable Clash Verge module, includes `clash-verge-rev` in the final user packages, and evaluates the system toplevel derivation.

## Commands

Chosen because the changes are NixOS module wiring, not runtime application logic. These evals directly prove the affected generated config and package graph without building unrelated packages.

The new `modules/desktop/apps/clash-verge.nix` file was marked with `git add -N` before the final package and toplevel eval rerun, so Git-backed flake validation includes the new module path.

```sh
nix eval --impure '.#nixosConfigurations.axiom.config.home.configFile."fcitx5/conf/classicui.conf".text'
```

Result: `"Theme=catppuccin-mocha-mauve\n"`.

```sh
nix eval --impure '.#nixosConfigurations.axiom.config.home.configFile."fcitx5/conf/classicui.conf".force'
```

Result: `true`.

```sh
nix eval --impure '.#nixosConfigurations.axiom.config.environment.etc."xdg/fcitx5/conf/classicui.conf".text'
```

Result: `"Theme=catppuccin-mocha-mauve\n\n"`.

```sh
nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); pkgs = flake.nixosConfigurations.axiom.pkgs; in pkgs.clash-verge-rev.pname or pkgs.clash-verge-rev.name'
```

Result: `"clash-verge-rev"`.

```sh
nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); in flake.nixosConfigurations.axiom.config.modules.desktop.apps."clash-verge".enable'
```

Result: `true`.

```sh
nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; in builtins.elem (cfg.modules.desktop.apps."clash-verge".package.pname or cfg.modules.desktop.apps."clash-verge".package.name) (map (p: p.pname or p.name) cfg.users.users.c1.packages)'
```

Result: `true`.

```sh
nix eval --impure '.#nixosConfigurations.axiom.config.system.build.toplevel.drvPath'
```

Result: `"/nix/store/rqrfm9jqsh5s4434x0cizcvs9chsphkr-nixos-system-axiom-25.11.20260203.e576e3c.drv"`.

## Warnings

The focused evals emit existing repository warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system` usage. These warnings are not introduced by this change.

## Skipped

No full rebuild was run. The acceptance criteria are module evaluation and generated config/package wiring for `axiom`; focused evals provide direct evidence at lower cost.
