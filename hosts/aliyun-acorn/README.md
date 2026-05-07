# aliyun-acorn

NixOS host/image target for importing into Alibaba Cloud ECS.

## Build

From the repository root:

```sh
nix build ./hosts/aliyun-acorn/image#aliyun-image
```

The image flake also exposes the explicit Linux package path:

```sh
nix build ./hosts/aliyun-acorn/image#packages.x86_64-linux.aliyun-image
```

The output is a QCOW2 disk image named with the `nixos-aliyun-acorn` base name.

## Import notes

- Import the QCOW2 image through Alibaba Cloud ECS custom image import.
- Match the imported image boot mode to UEFI/EFI; this host enables `systemd-boot` and EFI image support.
- First boot relies on generic QEMU guest support, DHCP via `systemd-networkd`, serial console on `ttyS0`, root partition growth, and cloud-init with the `AliYun` datasource enabled.
- Actual ECS first-boot validation is still required after upload/import; this repository task only produces the image target.
