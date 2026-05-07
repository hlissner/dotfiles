# Aliyun NixOS Image Host

Status: PR-backed implementation handoff
Task: `.legion/tasks/aliyun-nixos-image-host/`
Branch: `legion/aliyun-nixos-image-host-aliyun-image`

## Summary

Added `hosts/aliyun-acorn`, an `x86_64-linux` NixOS host and nested image flake for producing a QCOW2 image intended for Alibaba Cloud ECS custom-image import.

## Effective outcome

- New root flake host: `.#nixosConfigurations.aliyun-acorn` / `.#hostMetadata."aliyun-acorn"`.
- Image target: `./hosts/aliyun-acorn/image#aliyun-image`.
- Image format: QCOW2 via nixpkgs `virtualisation/disk-image.nix`.
- Boot/init assumptions: EFI/systemd-boot, QEMU guest profile, DHCP with systemd-networkd, serial console on `ttyS0`, partition growth, cloud-init datasource list including `AliYun`.

## Validation

Local validation passed for evaluation and dry-run:

- `nix eval --json .#hostMetadata."aliyun-acorn"`
- `nix eval --raw ./hosts/aliyun-acorn/image#aliyun-image.system`
- `nix build --dry-run ./hosts/aliyun-acorn/image#aliyun-image`
- `nix eval --raw .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath`

Full image realization remains blocked on the local Mac because no `x86_64-linux` builder is configured.

## Remaining external validation

Build on an `x86_64-linux` Nix builder, upload/import the QCOW2 into Alibaba Cloud ECS, and validate first boot with UEFI/EFI mode.
