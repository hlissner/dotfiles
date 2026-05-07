# Review: Aliyun NixOS Image Host

## Decision

PASS with documented environment limitation.

## Scope check

The change is within the approved contract:

- Adds a new `hosts/aliyun-acorn` NixOS host instead of modifying the existing Azure/acorn path.
- Adds a nested image flake for `nix build ./hosts/aliyun-acorn/image#aliyun-image`.
- Uses generic QEMU/cloud-init/disk-image plumbing, not Azure-specific modules.
- Adds only local documentation and Legion task artifacts.
- Does not upload images, call Alibaba Cloud APIs, change secrets, or touch the dirty main-checkout `hosts/charlie/default.nix`.

## Correctness / maintainability review

No blocking findings.

The host is discoverable in root flake metadata as `x86_64-linux`, and the image flake resolves to an `x86_64-linux` QCOW2 disk-image derivation. The implementation keeps provider-specific assumptions minimal and documents the remaining ECS import/first-boot validation requirement.

## Security lens

Security lens applied because the host config changes SSH/network/firewall/cloud-init behavior.

No blocking security findings:

- SSH exposure is explicit and consistent with a server image (`22/tcp`).
- Existing acorn-like service ports are visible in the firewall diff (`80`, `443`, `34197`).
- No new secrets, credentials, or cloud API permissions are introduced.
- cloud-init datasource is restricted to `AliYun`, `NoCloud`, and `None`; no privileged local credential material is embedded.

## Non-blocking notes

- The full image build still needs an `x86_64-linux` Nix builder; local macOS validation reached dry-run only.
- ECS first boot remains a real-world validation step after OSS/ECS import.
- Import should use UEFI/EFI mode to match the image boot configuration.
