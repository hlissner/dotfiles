# Axiom Host

## Goal
Add a new NixOS workstation host named `axiom` for C1's AMD Ryzen 9 9950X + NVIDIA RTX 5090 desktop, configured similarly to the existing `atlas` workstation while enabling NVIDIA GPU/CUDA support.

## Problem
The new machine needs a first-class host entry in the dotfiles flake so it can be installed/rebuilt consistently. `atlas` is the closest workstation baseline, but it currently only enables AMD CPU support and leaves GPU support commented out. `axiom` needs the same workstation ergonomics plus RTX 5090/NVIDIA profile wiring.

## Acceptance
- `hosts/axiom/default.nix` exists and defines an `x86_64-linux` NixOS host.
- `axiom` appears in root flake metadata and `nixosConfigurations`.
- Configuration is based on `atlas` style: workstation role, user `c1`, Shanghai network, desktop/dev/editor/shell/service/system modules, SSH agent, logrotate workaround, basic firewall.
- Hardware profile includes AMD CPU and NVIDIA GPU support for a Ryzen 9950X + RTX 5090 class workstation.
- Local evaluation succeeds, or any blocker is documented with evidence.
- Existing dirty work in the main checkout, especially `hosts/charlie/default.nix`, is not touched.
- Changes are delivered through the Legion git-worktree/PR lifecycle.

## Scope
- Add `hosts/axiom/default.nix`.
- Add Legion task, verification, review, walkthrough, and wiki writeback artifacts.
- Reuse existing hardware modules (`cpu/amd`, `gpu/nvidia`) rather than inventing new driver plumbing unless evaluation requires a small targeted fix.

## Non-goals
- Do not install or deploy the host onto real hardware.
- Do not partition disks or create disko config without actual device layout confirmation.
- Do not tune monitors, bootloader quirks, BIOS settings, overclocking, or fan curves yet.
- Do not modify unrelated hosts or global module semantics unless strictly necessary for evaluation.

## Assumptions
- The machine is x86_64-linux.
- The primary system partitions will use labels `nixos` and `BOOT`, matching `atlas`.
- The NIC name is not known yet; use NetworkManager plus a likely wired DHCP interface override and document that real hardware may need adjustment.
- RTX 5090 is new enough to use the existing `gpu/nvidia` profile with open NVIDIA kernel module and beta driver.

## Constraints
- Follow Legion workflow and `git-worktree-pr` envelope.
- Base branch is `origin/master`.
- Worktree path is `.worktrees/axiom-host`.
- Preserve main checkout dirty state.

## Risks
- RTX 5090 may require a newer/beta NVIDIA driver or nixpkgs revision than current flake provides; local evaluation can validate config shape but not physical driver runtime.
- Unknown NIC and disk layout may require adjustment during install.
- Full hardware validation requires booting the actual machine.

## Design Summary
Create `hosts/axiom/default.nix` by adapting `atlas`: keep the workstation/user/network/module baseline, add `gpu/nvidia`, and include a slightly more GPU-workstation-oriented local package set. Use NetworkManager to avoid overfitting to a single NIC name while preserving labeled root/boot filesystems. Evaluation and dry local checks are enough for this repo change; real install remains a separate hardware bring-up step.

## Phases
1. Create host config and task artifacts.
2. Evaluate root flake metadata and NixOS config.
3. Review scope and safety.
4. Write walkthrough/wiki evidence.
5. Push PR branch, create/merge PR if clean, clean up worktree and refresh main workspace.
