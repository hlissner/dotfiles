## Summary

- add `hosts/aliyun-acorn`, an x86_64 NixOS server host for Alibaba Cloud ECS image import experiments
- add `hosts/aliyun-acorn/image#aliyun-image`, a QCOW2 disk-image target built from the new host
- document build/import notes and Legion verification/review evidence

## Validation

- `nix eval --json .#hostMetadata."aliyun-acorn" | jq -c .`
- `nix eval --raw ./hosts/aliyun-acorn/image#aliyun-image.system`
- `nix build --dry-run ./hosts/aliyun-acorn/image#aliyun-image`
- `nix eval --raw .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath`

Full local image build is blocked on this Mac because no `x86_64-linux` builder is configured (`system = aarch64-darwin`).

## Notes

The QCOW2 still needs to be built on an x86_64 Linux builder, uploaded/imported into Alibaba Cloud ECS, and first-boot validated with UEFI/EFI mode.
