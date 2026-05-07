## Summary

- add `hosts/axiom`, a NixOS workstation host for the AMD Ryzen 9 9950X + RTX 5090 machine
- enable the existing AMD CPU + NVIDIA GPU/CUDA profile path for the new host
- fix a few current nixpkgs package/option renames required for workstation evaluation
- add Legion task, test, review, walkthrough, and wiki evidence

## Validation

- `nix eval --json .#hostMetadata.axiom | jq -c .`
- `nix eval --raw .#nixosConfigurations.axiom.config.system.name`
- `nix eval --json .#nixosConfigurations.axiom.config.hey.info.profiles.hardware | jq -c .`
- `nix eval --raw .#nixosConfigurations.axiom.config.hardware.nvidia.package.name`
- `nix eval --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
- `nix build --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel`

## Notes

Physical bring-up still needs confirmation of NIC name, disk labels, monitor layout, and RTX 5090 runtime behavior.
