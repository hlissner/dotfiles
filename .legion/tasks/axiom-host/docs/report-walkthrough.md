# Walkthrough: Axiom Host

Mode: implementation

## What changed

- Added `hosts/axiom/default.nix`, a new x86_64 NixOS workstation host for C1's AMD Ryzen 9 9950X + RTX 5090 machine.
- Based the host on the existing `atlas` workstation shape while enabling `gpu/nvidia` for RTX 5090/CUDA support.
- Included small nixpkgs compatibility updates required for the new workstation path to evaluate on current inputs:
  - `xdragon` -> `dragon-drop`
  - `ubuntu_font_family` -> `ubuntu-classic`
  - `vaapiVdpau` -> `libva-vdpau-driver`
  - `wrapGAppsHook` -> `wrapGAppsHook3`
  - `systemd.extraConfig` -> `systemd.settings.Manager.DefaultLimitNOFILE`

## Host shape

`axiom` is configured as a Shanghai workstation for user `c1`, with AMD CPU, NVIDIA GPU, audio/realtime audio, SSD, Bluetooth, Wi-Fi, BSPWM desktop, Rofi, Steam, Librewolf/Chrome, Foot/ST terminals, common dev tooling, Docker, Calibre, SSH, and NVIDIA `nvtop`.

## Validation evidence

See `docs/test-report.md`.

Validated locally:

- root flake discovers `hostMetadata.axiom` as an `x86_64-linux` NixOS host;
- `system.name` resolves to `axiom`;
- hardware profile includes `cpu/amd` and `gpu/nvidia`;
- NVIDIA package resolves to `nvidia-x11-580.119.02-6.12.68`;
- NixOS top-level derivation evaluates;
- top-level dry-run succeeds.

## Review evidence

See `docs/review-change.md`.

Review decision: PASS.

Security lens was applied because the host enables SSH and firewall rules. No blocking security findings were identified.

## Remaining hardware bring-up

Confirm actual NIC name, partition labels, display setup, and RTX 5090 runtime behavior on the physical machine during install/first boot.
