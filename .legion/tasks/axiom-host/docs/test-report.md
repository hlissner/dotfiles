# Test Report: Axiom Host

## Why these checks

The change adds a new NixOS host and touches existing desktop/GPU package references needed for evaluation. The strongest local validation is to prove the root flake discovers `axiom`, the host has the expected hardware profile, NVIDIA resolves to a current driver package, and the NixOS top-level derivation evaluates/plans successfully.

## Commands run

```sh
nix eval --json .#hostMetadata.axiom | jq -c .
nix eval --raw .#nixosConfigurations.axiom.config.system.name
nix eval --json .#nixosConfigurations.axiom.config.hey.info.profiles.hardware | jq -c .
nix eval --raw .#nixosConfigurations.axiom.config.hardware.nvidia.package.name
nix eval --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath
nix build --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel
```

## Results

- `hostMetadata.axiom` returns an `x86_64-linux` NixOS host under `hosts/axiom`.
- `system.name` returns `axiom`.
- Hardware profile returns:
  ```json
  ["cpu/amd","gpu/nvidia","audio","audio/realtime","ssd","bluetooth","wifi"]
  ```
- NVIDIA package resolves to:
  ```text
  nvidia-x11-580.119.02-6.12.68
  ```
- Top-level derivation evaluates to:
  ```text
  /nix/store/4gl4ygiqjraml3ryyrzzp4q6sln3whb2-nixos-system-axiom-25.11.20260203.e576e3c.drv
  ```
- `nix build --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` succeeds.

## Warnings observed

Evaluation emits existing repository warnings about `specialArgs.pkgs`, `hardware.pulseaudio` rename, `i18n.inputMethod.enabled` future removal, and `system` rename. These are not introduced by the `axiom` host and do not block evaluation.

## Skipped / remaining validation

- Full build/boot was not performed on this Mac.
- Real hardware validation still needs install/boot on the Ryzen 9950X + RTX 5090 machine.
- NIC name and disk labels should be confirmed during install; first pass assumes labels `nixos` and `BOOT`, plus NetworkManager.
