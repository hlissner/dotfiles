# Review: Axiom Host

## Decision

PASS.

## Scope check

The change is within the approved task scope:

- Adds `hosts/axiom/default.nix` for a Ryzen 9950X + RTX 5090 workstation.
- Reuses existing profiles (`cpu/amd`, `gpu/nvidia`) and follows the `atlas` workstation shape.
- Keeps disk/boot assumptions minimal and documents remaining hardware bring-up work.
- Does not touch the main checkout dirty file `hosts/charlie/default.nix`.

The PR also includes four small existing-package compatibility fixes needed for current nixpkgs evaluation of an NVIDIA/X11/Steam/Rofi workstation:

- `xdragon` -> `dragon-drop`
- `ubuntu_font_family` -> `ubuntu-classic`
- `vaapiVdpau` -> `libva-vdpau-driver`
- `wrapGAppsHook` -> `wrapGAppsHook3`
- `systemd.extraConfig` -> `systemd.settings.Manager.DefaultLimitNOFILE`

These are acceptable as narrowly targeted evaluation fixes discovered while validating the new host.

## Correctness / maintainability review

No blocking findings.

Evidence from `docs/test-report.md` shows the host is discoverable, has the expected hardware profile, resolves NVIDIA driver `nvidia-x11-580.119.02-6.12.68`, evaluates a top-level derivation, and passes a top-level dry-run.

The first-pass hardware config intentionally avoids overfitting unknown real hardware details. NIC and partition labels remain install-time confirmation items.

## Security lens

Security lens applied because the host opens network services/firewall ports and enables SSH.

No blocking security findings:

- SSH exposure is explicit and consistent with existing workstation/server patterns.
- Firewall ports mirror the `atlas`-style baseline plus high ephemeral ranges; this is pre-existing pattern reuse, not a new public service stack.
- No secrets, credentials, cloud permissions, signing keys, or auth logic are introduced.

## Non-blocking notes

- Confirm actual NIC name during install; `enp14s0` is a first-pass guess with NetworkManager also enabled.
- Confirm disk labels `nixos` and `BOOT` during installation.
- RTX 5090 runtime validation still requires booting the actual machine.
