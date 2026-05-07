# Test Report: Aliyun NixOS Image Host

## Why these checks

The change adds a NixOS host and a nested image flake, so the strongest cheap local evidence is:

1. prove the host is discovered by the root flake metadata;
2. prove the image attribute resolves to an `x86_64-linux` derivation;
3. dry-run the image build to validate evaluation, dependency closure planning, and the selected build target without requiring a Linux builder on this Mac.

A full `nix build` is the final end-to-end gate, but this machine cannot execute `x86_64-linux` builders locally.

## Commands run

```sh
nix eval --json .#hostMetadata."aliyun-acorn" | jq -c .
nix eval --raw ./hosts/aliyun-acorn/image#aliyun-image.system
nix build --dry-run ./hosts/aliyun-acorn/image#aliyun-image
nix eval --raw .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath
```

## Results

- `hostMetadata."aliyun-acorn"` returns:
  ```json
  {"os":"nixos","path":"/nix/store/...-source/hosts/aliyun-acorn","system":"x86_64-linux"}
  ```
- `./hosts/aliyun-acorn/image#aliyun-image.system` returns `x86_64-linux`.
- `nix build --dry-run ./hosts/aliyun-acorn/image#aliyun-image` succeeds and plans the `nixos-disk-image` derivation.
- The host top-level evaluates to a NixOS system derivation:
  ```text
  /nix/store/5zhjadjy5bg71018as43jkbc3n7jghwh-nixos-system-aliyun-acorn-25.11.20260203.e576e3c.drv
  ```

## Full build blocker

A full local image build was attempted:

```sh
nix build ./hosts/aliyun-acorn/image#packages.x86_64-linux.aliyun-image --no-link
```

It fails on this Mac because no Linux builder is configured:

```text
Required system: 'x86_64-linux' with features {}
Current system: 'aarch64-darwin' with features {apple-virt, benchmark, big-parallel, nixos-test}
```

Local Nix config confirms:

```text
builders =
extra-platforms = x86_64-darwin
system = aarch64-darwin
```

## Skipped / remaining validation

- Full QCOW2 realization requires an `x86_64-linux` Nix builder.
- Alibaba Cloud ECS import and first boot are not validated locally; they require uploading the produced QCOW2 to OSS/ECS and booting an instance.
