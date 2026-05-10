# Test Report

## Summary
- Result: PASS
- Scope: focused Axiom Nix evaluation for the Fcitx5 Wayland frontend and managed `GTK_IM_MODULE` environment state.

## Commands
```sh
nix eval ".#nixosConfigurations.axiom.config.i18n.inputMethod.fcitx5.waylandFrontend"
nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; in { session = builtins.hasAttr "GTK_IM_MODULE" cfg.environment.sessionVariables; variables = builtins.hasAttr "GTK_IM_MODULE" cfg.environment.variables; }'
nix eval ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"
```

## Evidence
- `waylandFrontend` evaluates to `true` for `axiom`.
- Managed environment checks evaluate to `{ session = false; variables = false; }`, so `GTK_IM_MODULE` is not exported through `environment.sessionVariables` or `environment.variables`.
- Axiom system toplevel evaluation produced `/nix/store/r6jf57za6d7jslxibdxynr8km2li8vnd-nixos-system-axiom-25.11.20260203.e576e3c.drv` after rebasing onto the latest `origin/master`.

## Warnings
- Nix emitted existing evaluation warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system`; these are unrelated to this input-method change.

## Why These Checks
- The first command proves the reusable module policy turns on the Fcitx5 Wayland frontend for the target Wayland host.
- The second command directly validates the reported warning condition by checking whether the managed config exports `GTK_IM_MODULE`.
- The third command confirms the changed NixOS configuration still evaluates to a system derivation without building the full system.
