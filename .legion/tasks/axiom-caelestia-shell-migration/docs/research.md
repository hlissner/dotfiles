# Research: Axiom Caelestia Shell Migration

## Sources Read

- Local task contract: `.legion/tasks/axiom-caelestia-shell-migration/plan.md`
- Current desktop modules: `modules/desktop/hyprland.nix`, `modules/desktop/quickshell.nix`, `modules/home.nix`
- Current active config roots: `config/quickshell/ii`, `config/hypr`, `config/matugen`, `config/fuzzel`
- Current wiki truth: `.legion/wiki/decisions.md`, `.legion/wiki/patterns.md`, `.legion/wiki/maintenance.md`
- Upstream Caelestia README: `https://github.com/caelestia-dots/shell`
- Upstream Caelestia flake/package/HM module: `flake.nix`, `nix/default.nix`, `nix/hm-module.nix`
- Upstream Caelestia dots keybind reference: `caelestia-dots/caelestia/hypr/hyprland/keybinds.conf`

## Current Local State

- `modules/desktop/quickshell.nix` is now end4-specific despite its generic name. It builds a custom `axiom-quickshell`, wraps QML import paths, creates an `illogical-impulse` Python environment, starts `quickshell --config ii`, links `quickshell/ii`, `matugen`, and `fuzzel`, and exports a service PATH for end4 helpers.
- `modules/desktop/hyprland.nix` depends on `config.modules.desktop.quickshell`, defaults it on, exports `ILLOGICAL_IMPULSE_VIRTUAL_ENV`, and generates end4-specific `$qsConfig`, start-menu/search IPC, and state paths.
- `config/hypr/hyprland.conf` is an end4 source layering root. It sources `hyprland/*`, `custom/*`, and `hyprland/shellOverrides/main.conf`.
- `config/hypr/hyprland/keybinds.conf`, `hypridle.conf`, `hyprland/rules.conf`, and related files contain end4/Quickshell global shortcut names such as `quickshell:searchToggleRelease`, `quickshell:sidebarLeftToggle`, and `quickshell:wallpaperSelectorToggle`.
- The wiki currently says end4 `ii` is active product truth. This must be rewritten during closing so future work does not start from obsolete end4 assumptions.

## Upstream Caelestia Findings

- The README offers a first-class Nix path: add `caelestia-shell` as a flake input and consume `caelestia-shell.packages.<system>.default` or another package output.
- The README warns the default package does not enable the CLI required for full functionality; the `with-cli` package should be used.
- The upstream package builds the shell, QML plugin, extras library, and a `caelestia-shell` wrapper around `qs -p <store>/share/caelestia-shell`.
- The upstream wrapper sets `FONTCONFIG_FILE`, `CAELESTIA_LIB_DIR`, `CAELESTIA_XKB_RULES_PATH`, and a PATH containing runtime dependencies. With `with-cli`, the Caelestia CLI is included in that runtime PATH.
- The upstream HM module starts `${shell}/bin/caelestia-shell`, optionally writes `caelestia/shell.json` and `caelestia/cli.json`, and can add the CLI package to `home.packages`.
- Upstream keybinds use Hyprland global shortcuts under the `caelestia:*` namespace for launcher, sidebar, session, lock, media, brightness, screenshots, and related shell actions. They also use CLI commands such as `caelestia shell -d`, `caelestia screenshot`, `caelestia record`, `caelestia clipboard`, and `caelestia emoji`.

## Integration Constraints

- This repository intentionally wraps Home Manager behind local `home.*` aliases and comments that Home Manager should not become another broad black box. Directly importing the upstream HM module would work in principle but weakens the local integration boundary.
- Existing Linux desktop services are modeled through NixOS `systemd.user.services` and the local `hyprland-session.target`, not primarily through HM-generated systemd services.
- Host facts must remain generated in Nix: monitor/workspace config, XKB layout, default apps, rules, session startup, and fallback keybinds.
- Darwin must not import Linux-only Caelestia packages or modules.

## Design Implications

- Best durable path: consume upstream Caelestia's Nix package output, but keep a local `modules.desktop.caelestia` integration module for service, config JSON, package exposure, and reload hook.
- The old `modules.desktop.quickshell` module should be deleted or replaced, not kept as an inactive end4 compatibility layer.
- The Hyprland base should be reduced to repository-owned local config with `source=custom/*.conf` plus generated `monitors.conf`/`workspaces.conf`, rather than keeping end4's source tree and shell override directory.
- Caelestia keybinds should be introduced through Nix-generated `custom/keybinds.conf` using absolute package paths where feasible. A complete copy of upstream Caelestia dots Hyprland config is not necessary for the shell package to run and would reintroduce another external desktop source tree.
- `config/fuzzel` and `config/matugen` appear tied to end4 fallback/theme integration in current active desktop scope. They should be removed unless implementation finds another active non-end4 consumer.

## Verification Implications

- Strong static checks should confirm `systemd.user.services.caelestia-shell.serviceConfig.ExecStart` points at `caelestia-shell`, the package name comes from the `caelestia-shell` flake input, and no active service starts `quickshell --config ii`.
- Static scans should distinguish active runtime files from historical Legion task evidence when checking for end4 references.
- Nix eval/build should cover `nixosConfigurations.axiom.config.system.build.toplevel`, generated Hyprland files, user package presence, service environment, and Home Manager managed config files.
- Hyprland syntax validation should combine checked-in and generated config if practical.
- Live validation should restart the Caelestia user service and exercise launcher/sidebar/media/brightness/screenshot only when a live Hyprland session is available.
