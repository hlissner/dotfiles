# Axiom Host

Status: PR-backed implementation handoff
Task: `.legion/tasks/axiom-host/`
Branch: `legion/axiom-host-nixos-host`

## Summary

Added `hosts/axiom`, an `x86_64-linux` NixOS workstation host for C1's AMD Ryzen 9 9950X + RTX 5090 desktop.

## Effective outcome

- New root flake host: `.#nixosConfigurations.axiom` / `.#hostMetadata.axiom`.
- Workstation baseline adapted from `atlas`.
- Hardware profile: `cpu/amd`, `gpu/nvidia`, audio/realtime audio, SSD, Bluetooth, Wi-Fi.
- NVIDIA package currently evaluates to `nvidia-x11-580.119.02-6.12.68`.
- Includes compatibility fixes for current nixpkgs package/option renames encountered while enabling the workstation path.

## Validation

Local validation passed for metadata, system name, hardware profile, NVIDIA package resolution, top-level derivation evaluation, and top-level dry-run.

## Remaining hardware validation

During physical install, confirm NIC name, disk labels `nixos`/`BOOT`, monitor layout, and RTX 5090 runtime behavior.
