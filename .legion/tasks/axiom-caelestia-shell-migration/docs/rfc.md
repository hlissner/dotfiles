# RFC: Replace End4 With Caelestia Shell On Axiom

> Status: design approved
> Type: RFC Standard, implementation-bound
> Date: 2026-05-10
> Task: `.legion/tasks/axiom-caelestia-shell-migration/`

## Executive Summary

Axiom should stop treating the vendored end4 `ii` tree as desktop product truth and switch to Caelestia shell through Caelestia's upstream Nix package. The migration should not repeat the end4 import pattern. Caelestia already provides a flake package, CLI-enabled package output, wrapper, QML plugin, extras library, and optional Home Manager module; this repository should consume the package while keeping local NixOS ownership over systemd, XDG config, Hyprland host facts, and session startup.

Decision: add `caelestia-shell` as a flake input following `nixpkgs-unstable`; add a local Linux-only `modules.desktop.caelestia` integration module using `packages.${system}.with-cli`; remove the end4-specific Quickshell module and vendored `ii`/matugen/fuzzel/shellOverride sources; rebuild Hyprland around a small local base plus Nix-generated overrides; update docs/wiki to mark end4 as superseded.

## Goals

- Make the active Axiom shell service start Caelestia shell.
- Install Caelestia via the README's Nix-supported path and use the CLI-enabled package.
- Remove active end4 `ii` runtime source, service, variables, keybinds, matugen/fuzzel shell integration, and IllogicalImpulse assumptions.
- Preserve repository ownership of Hyprland startup, generated host facts, XDG config, systemd user target, and rollback through Nix generations.
- Keep Darwin isolated from Linux desktop concerns.

## Non-Goals

- Do not run Caelestia's manual install flow or clone shell source into live `~/.config`.
- Do not vendor Caelestia shell source unless package validation proves upstream packaging is unusable.
- Do not keep end4 as a fallback shell product.
- Do not port end4 IPC or Waffle features into Caelestia.
- Do not copy the full Caelestia dots repository into this repo.

## Baseline

- Current active Quickshell service starts `quickshell --config ii`.
- Current `modules.desktop.quickshell` is end4-specific despite the generic option name.
- Current Hyprland checked-in root is an imported end4 layering file that sources end4 keybinds, rules, variables, and shell overrides.
- Current wiki truth says end4 `ii` is the active product direction.
- Upstream Caelestia shell provides a Nix package and recommends `with-cli` for full functionality.

## Alternatives

### A: Manual Caelestia install under `~/.config/quickshell/caelestia`

- Pros: mirrors the README manual path and is easy to edit live.
- Cons: violates repository/Nix ownership, creates unmanaged home state as product source, bypasses review/rollback, and repeats the problem this repo had with upstream shell imports.
- Decision: reject.

### B: Import Caelestia's Home Manager module directly

- Pros: upstream module already writes config JSON, installs packages, and creates a user service.
- Cons: service would be owned by HM rather than the repository's existing NixOS `hyprland-session.target` pattern; config would bypass the local `home.configFile` abstraction; target defaults depend on HM's `wayland.systemd.target`; repo comments explicitly avoid broad HM ownership.
- Decision: reject as primary architecture. It remains a reference for option names and service shape.

### C: Local NixOS integration module consuming upstream package

- Pros: follows the README Nix package path, avoids vendoring, keeps local systemd/XDG/session conventions, allows Axiom-specific host policy, and keeps rollback through Nix generations.
- Cons: duplicates a small amount of upstream HM module wiring and must track package output names.
- Decision: choose.

### D: Vendor Caelestia shell source like end4

- Pros: maximum local control and review of upstream QML.
- Cons: creates another large source import and maintenance burden despite upstream already packaging the shell.
- Decision: reject unless upstream package proves unusable.

## Design

### Flake Input

Add a Linux desktop input:

```nix
caelestia-shell = {
  url = "github:caelestia-dots/shell";
  inputs.nixpkgs.follows = "nixpkgs-unstable";
};
```

Use `hey.inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli` for the shell package on Linux. If direct CLI command paths are needed outside the wrapper, use `hey.inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default` rather than relying on ambient PATH.

### Local Module Boundary

Replace the active end4-specific Quickshell integration with a local module such as `modules/desktop/caelestia.nix`:

- Options: `enable`, `package`, `cliPackage`, `settings`, `cli.settings`, and possibly `serviceName` only if needed.
- Config when enabled: add shell and CLI package to user/system package exposure; create `systemd.user.services.caelestia-shell` under `hyprland-session.target`; write `home.configFile."caelestia/shell.json"` and optional `home.configFile."caelestia/cli.json"`; add a reload hook that restarts the Caelestia service.
- Service command: `${cfg.package}/bin/caelestia-shell`.
- Service environment: keep `QT_QPA_PLATFORM=wayland`; add only host-required variables not already set by the upstream wrapper.

Do not import Caelestia's HM module as the primary integration. The implementation can mirror its config JSON semantics but should remain inside this repository's NixOS module system.

### Hyprland Ownership

Rewrite checked-in `config/hypr/hyprland.conf` as a local base, not an imported end4 root. It should source only repository-owned or Nix-generated files:

- `custom/env.conf`
- `custom/variables.conf`
- `custom/execs.conf`
- `custom/general.conf`
- `custom/rules.conf`
- `custom/keybinds.conf`
- `monitors.conf`
- `workspaces.conf`

Delete end4-specific `config/hypr/hyprland/**` files unless a specific helper remains independently useful and is renamed out of the end4 source tree. Keep repository-owned helper scripts under `config/hypr/bin` and `config/hypr/hooks` if they are still used by `hey` commands or host hooks.

Generated Hyprland overrides should be updated:

- Remove `ILLOGICAL_IMPULSE_VIRTUAL_ENV`, `$qsConfig`, end4 wallpaper restore, and end4 IPC fallbacks.
- Add `$caelestiaShell` and `$caelestiaCli` absolute command variables where useful.
- Map primary shell keybinds to Caelestia global shortcuts and/or CLI commands. Initial scope should include launcher, sidebar/session/lock if configured, media/brightness, screenshot/record where packages are available, restart, and core app launchers.
- Keep Axiom XKB layout and host app/window rules in generated files.

### Source Deletion Boundary

Remove active end4 source and support config:

- `config/quickshell/ii/**`
- `config/matugen/**` unless another active non-end4 consumer is found
- `config/fuzzel/**` unless retained as a deliberate standalone launcher fallback
- end4-specific `config/hypr/hyprland/**` and `config/hypr/hypridle.conf`/`hyprlock` pieces that only dispatch to end4 `quickshell:*`
- root `end4.md`

Historical `.legion/tasks/**` evidence can remain as task history. Wiki current-truth files must be updated at closeout so future work does not treat end4 as active.

### Caelestia Settings

Create minimal generated `caelestia/shell.json` rather than copying the README's full example. Initial settings should only encode host policy that is already known:

- default apps: terminal `foot`, explorer `thunar`, audio settings `pavucontrol`, playback `mpv` if present
- wallpaper directory if this repository wants to align with an existing user path
- disable dangerous launcher actions unless explicitly desired
- laptop/battery settings only if host facts require them

Avoid writing exhaustive defaults. Let upstream defaults evolve.

### Rollback

- Merge-time rollback: revert the PR.
- Runtime rollback: select the previous NixOS generation.
- Emergency local rollback may manually start a previous generation's `quickshell.service`, but the repository must not preserve end4 fallback as product truth.

## Verification Strategy

- Evaluate the Caelestia package path and service command for Axiom.
- Evaluate generated `caelestia/shell.json`, Hyprland keybinds, env, rules, monitor, and workspace files.
- Confirm no active Nix module or checked-in active config references `quickshell --config ii`, `IllogicalImpulse`, `ILLOGICAL_IMPULSE`, `config/quickshell/ii`, or end4 IPC names.
- Run `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` or the strongest available equivalent.
- Run `git diff --check`.
- If practical, run Hyprland config verification against combined generated/checked-in config using the evaluated Hyprland binary.
- If a live Hyprland user session is available, restart the Caelestia service and smoke launcher/sidebar/session/media/screenshot paths. If not, record that live layer-shell behavior remains unexercised.

## Decision

Proceed with option C: consume upstream Caelestia's CLI-enabled Nix package through a local NixOS integration module, delete end4 active source/config, and rebuild Hyprland around repository-owned generated host facts.
