# Log: axiom-caelestia-shell-migration

## 2026-05-10

- User requested Legion workflow for removing end4 configuration and installing `caelestia-dots/shell` according to the README, with no backward compatibility requirement and an architecture-first approach.
- Entry gate selected brainstorm because no explicit existing task id/path was provided.
- Repository context shows current wiki and modules treat end4 `ii` as active desktop truth; this task intentionally supersedes that direction.
- Upstream Caelestia README and flake show a first-class Nix path. The durable default is to use the upstream flake package with CLI support rather than manual clone/build or vendoring the shell source.
- Materialized task contract under `.legion/tasks/axiom-caelestia-shell-migration/`. Next step is design gate because this changes product direction, flake inputs, desktop services, Hyprland config, and deletion boundaries.
- Wrote design artifacts under `docs/`: research, RFC, and implementation plan. RFC chooses a local NixOS integration module consuming upstream `caelestia-shell.packages.<system>.with-cli`, with end4 active source deletion and a local Hyprland base.
- Review RFC returned PASS with no blocking findings. Non-blocking implementation cautions: preflight the `with-cli` package output, exclude historical `.legion/tasks/**` from active end4 scans, and record global-shortcut versus CLI-backed keybinds.
- Opened isolated worktree `.worktrees/axiom-caelestia-shell-migration/` on branch `legion/axiom-caelestia-shell-migration` from `origin/master`.
- Preflighted upstream package output with `nix eval --raw github:caelestia-dots/shell#packages.x86_64-linux.with-cli.name`, which returned `caelestia-shell-1.0.0`.
- Added `caelestia-shell` flake input following `nixpkgs-unstable` and locked upstream shell/CLI/quickshell inputs.
- Replaced the end4-specific `modules/desktop/quickshell.nix` with `modules/desktop/caelestia.nix`, a local NixOS integration module that installs the CLI-enabled shell package, writes minimal `caelestia/shell.json`, and starts `caelestia-shell.service` under `hyprland-session.target`.
- Updated Hyprland integration to default-enable Caelestia, remove IllogicalImpulse/env/config-name coupling, generate Caelestia global-shortcut and CLI-backed keybinds, and keep host monitor/workspace/input/rules under Nix-generated `custom/*.conf` files.
- Simplified checked-in `config/hypr/hyprland.conf` to source only repository-owned generated/local files and rewrote `hypridle.conf` plus OSD fallback to avoid end4/legacy Quickshell IPC.
- Removed active local shell source/config trees: `config/quickshell`, `config/matugen`, `config/fuzzel`, and end4 imported `config/hypr/hyprland`.
- Updated README desktop table from Quickshell/Fuzzel to Caelestia Shell.
- Targeted evals passed for Caelestia service ExecStart, generated `caelestia/shell.json`, generated Hyprland keybinds, and user package presence.
- Verification completed. Active source scan over `config`, `modules`, and `README.md` found no end4/ii/legacy Quickshell references; `git diff --check` passed after fixing RFC whitespace; `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed. Live service restart was skipped because the tool shell has no Wayland/Hyprland session variables.
- Readiness review returned PASS with no blocking correctness, maintainability, scope, or security/privacy findings. Security lens was applied for screenshot/record/clipboard/global-shortcut entrypoints; no new exploitable trust-boundary issue was found. Residual live-session and Hyprland `--verify-config` checks are recorded as post-deployment follow-up.
- Generated implementation-mode `docs/report-walkthrough.md` and `docs/pr-body.md` from existing design, verification, and review evidence.
- Completed Legion wiki writeback: added `wiki/tasks/axiom-caelestia-shell-migration.md`, updated current desktop decisions/patterns/maintenance from end4 `ii` to Caelestia Shell, and marked superseded end4 task summaries historical where they were still active current-truth pages.
