# Walkthrough: Aliyun NixOS Image Host

Mode: implementation

## What changed

- Added `hosts/aliyun-acorn/default.nix`, a new `x86_64-linux` NixOS server host for Alibaba Cloud ECS image import experiments.
- Added `hosts/aliyun-acorn/image/flake.nix`, a nested image flake exposing `aliyun-image` as a QCOW2 disk image target.
- Added `hosts/aliyun-acorn/README.md` with local build commands and Alibaba Cloud ECS import notes.
- Added Legion task evidence under `.legion/tasks/aliyun-nixos-image-host/`.

## Why

The existing `hosts/acorn/azure-image` path is Azure-specific. Alibaba Cloud ECS does not have an upstream nixpkgs cloud image module, but it can import generic disk image formats. This change creates a provider-light path based on nixpkgs `virtualisation/disk-image.nix`, QEMU guest support, cloud-init, DHCP networking, serial console, root growth, and EFI boot.

## Validation evidence

See `docs/test-report.md`.

Validated locally:

- root flake discovers `hostMetadata."aliyun-acorn"` as `x86_64-linux` NixOS;
- `./hosts/aliyun-acorn/image#aliyun-image.system` resolves to `x86_64-linux`;
- `nix build --dry-run ./hosts/aliyun-acorn/image#aliyun-image` succeeds;
- host top-level evaluates to a NixOS system derivation.

Full local image realization is blocked by this machine's builder environment: `aarch64-darwin` has no configured `x86_64-linux` builder.

## Review evidence

See `docs/review-change.md`.

Review decision: PASS with documented environment limitation.

Security lens was applied because the change touches SSH/network/firewall/cloud-init behavior. No blocking security findings were identified; no secrets or cloud API credentials were introduced.

## Remaining real-world step

After building on an `x86_64-linux` Nix builder, upload/import the QCOW2 through Alibaba Cloud ECS custom image import and validate first boot with UEFI/EFI mode.
