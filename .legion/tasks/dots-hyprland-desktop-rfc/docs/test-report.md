# Test Report: Dots Hyprland Desktop Phase 4

> Date: 2026-05-09
> Worktree: `.worktrees/dots-hyprland-desktop-rfc/`
> Branch: `legion/dots-hyprland-desktop-rfc-phase4-services`

## Summary

PASS with runtime caveats.

The Axiom NixOS toplevel builds successfully after the Phase 4 changes. Targeted evaluation confirms the new declarative service substrate is present: `cliphist` clipboard watcher, keyring, polkit, power profiles, i2c/DDC support, required user groups, Material Symbols / Google Sans-style font mapping, and Phase 4 packages. Python helper syntax parses successfully. Live Quickshell/Hyprland runtime checks were not run because this environment is not the user's graphical Axiom session.

## Commands

### Targeted Nix Evaluation

Command:

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake "path:/home/c1/dotfiles/.worktrees/dots-hyprland-desktop-rfc").nixosConfigurations.axiom.config; names = builtins.map (p: p.name or (builtins.toString p)) c.environment.systemPackages; has = needle: builtins.any (n: builtins.match (".*" + needle + ".*") n != null) names; in { quickshellExec = c.systemd.user.services.quickshell.serviceConfig.ExecStart; clipboardExec = c.systemd.user.services.axiom-clipboard-history.serviceConfig.ExecStart; clipboardBackend = c.systemd.user.services.quickshell.environment.AXIOM_CLIPBOARD_BACKEND; polkitEnabled = c.security.polkit.enable; polkitAgent = c.systemd.user.services ? axiom-polkit-agent; powerProfiles = c.services.power-profiles-daemon.enable; i2cHardware = c.hardware.i2c.enable; i2cGroupExists = c.users.groups ? i2c; userGroups = c.users.users.c1.extraGroups; gnomeKeyring = c.services.gnome.gnome-keyring.enable; guideLinked = c.home.configFile ? "axiom-desktop/guide.md"; hasCliphist = has "cliphist"; hasDdcutil = has "ddcutil"; hasPowerProfilesPackage = has "power-profiles-daemon"; hasMatugen = has "matugen"; hasCava = has "cava"; hasSongrec = has "songrec"; }'
```

Result: PASS.

Key evidence:

```json
{
  "clipboardBackend": "cliphist",
  "clipboardExec": "/nix/store/...-wl-clipboard-2.2.1/bin/wl-paste --type text --watch /nix/store/...-cliphist-0.7.0/bin/cliphist store",
  "gnomeKeyring": true,
  "guideLinked": false,
  "hasCava": true,
  "hasCliphist": true,
  "hasDdcutil": true,
  "hasMatugen": true,
  "hasPowerProfilesPackage": true,
  "hasSongrec": true,
  "i2cGroupExists": true,
  "i2cHardware": true,
  "polkitAgent": true,
  "polkitEnabled": true,
  "powerProfiles": true,
  "userGroups": ["wheel", "video", "input", "i2c", "gamemode", "audio", "docker", "ydotool"]
}
```

Why this command was chosen: it directly proves the NixOS configuration contains the Phase 4 service substrate requested by the contract without requiring a graphical runtime session.

### Font Mapping Evaluation

Command:

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake "path:/home/c1/dotfiles/.worktrees/dots-hyprland-desktop-rfc").nixosConfigurations.axiom.config; names = builtins.map (p: p.name or (builtins.toString p)) (c.environment.systemPackages ++ c.fonts.packages); has = needle: builtins.any (n: builtins.match (".*" + needle + ".*") n != null) names; in { hasMaterialSymbols = has "material-symbols"; hasGoogleSansCode = has "googlesans-code"; hasGoogleFontsBundle = has "google-fonts"; clipboardBackend = c.systemd.user.services.quickshell.environment.AXIOM_CLIPBOARD_BACKEND; powerProfiles = c.services.power-profiles-daemon.enable; polkit = c.security.polkit.enable; i2c = c.hardware.i2c.enable; }'
```

Result: PASS.

Key evidence:

```json
{
  "clipboardBackend": "cliphist",
  "hasGoogleFontsBundle": false,
  "hasGoogleSansCode": true,
  "hasMaterialSymbols": true,
  "i2c": true,
  "polkit": true,
  "powerProfiles": true
}
```

Why this command was chosen: `end4.md` requires Material Symbols / Google Sans-style font coverage. The implementation intentionally maps that requirement to `material-symbols` plus the narrower `googlesans-code` package rather than the very large `google-fonts` bundle.

### Python Helper Syntax

Command:

```sh
python3 -c 'import ast, pathlib; [ast.parse(path.read_text(), filename=str(path)) for path in [pathlib.Path("config/quickshell/axiom-shell/search/axiom-search-helper.py"), pathlib.Path("config/quickshell/axiom-shell/controls/axiom-control-helper.py")]]'
```

Result: PASS, no output.

Why this command was chosen: the changed helper scripts provide cliphist, brightness, power-profile, and resource status behavior. Parsing them catches Python syntax errors without writing `__pycache__` artifacts.

### Old Guide References In Active Shell/Modules

Commands:

```sh
# Grep tool search: config/quickshell/axiom-shell, include *.qml, pattern axiom-desktop|Axiom Desktop Guide|Open Axiom guide|guide.md|HELP
# Grep tool search: modules/desktop, include *.nix, pattern axiom-desktop|Axiom Desktop Guide|guide.md
```

Result: PASS, no active QML or desktop module references found.

Why this check was chosen: `end4.md` says old Axiom guide/buttons do not need to survive. This verifies active shell/module paths no longer link or launch the old guide. Historical Legion evidence still mentions the removed guide and was intentionally not rewritten.

### Axiom Toplevel Build

Command:

```sh
nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link
```

Result: PASS.

The successful run completed after narrowing the Google Sans-style font mapping from `google-fonts` to `googlesans-code`.

Why this command was chosen: it is the strongest available repository-local validation that changed NixOS modules, services, packages, user groups, PAM/keyring settings, and home-manager file changes compose into a buildable Axiom system.

### Post-Review Cleanup Check

Command:

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake "path:/home/c1/dotfiles/.worktrees/dots-hyprland-desktop-rfc").nixosConfigurations.axiom.config; names = builtins.map (p: p.name or (builtins.toString p)) c.environment.systemPackages; has = needle: builtins.any (n: builtins.match (".*" + needle + ".*") n != null) names; in { hasHyprpolkitagent = has "hyprpolkitagent"; polkitAgent = c.systemd.user.services ? axiom-polkit-agent; polkitEnabled = c.security.polkit.enable; }'
```

Result: PASS.

Key evidence:

```json
{"hasHyprpolkitagent": false, "polkitAgent": true, "polkitEnabled": true}
```

Why this command was chosen: the change review noted the unused `hyprpolkitagent` package. This confirms the unused package was pruned while the configured KDE polkit agent remains enabled.

The Axiom toplevel build was rerun after this cleanup with the same `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` command and passed.

## Failures Found And Fixed

- Initial `nix build` failed because enabling `gnome-keyring` also enabled `services.gnome.gcr-ssh-agent`, which conflicts with Axiom's existing `programs.ssh.startAgent`. Fix: `modules/services/gnome-keyring.nix` now disables `services.gnome.gcr-ssh-agent`, preserving Axiom's existing SSH agent ownership.
- A subsequent `nix build` attempt exceeded the 15 minute timeout while pulling/building the broad `google-fonts` bundle. Fix: use `googlesans-code` plus `material-symbols`, which satisfies the current Google Sans-style requirement without importing the entire Google Fonts package.

## Warnings

`cliphist` retention note: `maxEntries` and `maxEntryBytes` currently bound shell display/readback behavior. The `cliphist store` database itself is not pruned by this PR; retention policy remains a runtime/privacy follow-up.

The Nix commands emitted existing repository/channel warnings:

- `specialArgs.pkgs` means some nixpkgs options/overlays are ignored.
- `mesa.drivers` is deprecated.
- `hardware.pulseaudio` has been renamed to `services.pulseaudio`.
- `system` has been renamed to/replaced by `stdenv.hostPlatform.system`.

These warnings are not introduced by this task's Phase 4 changes and did not prevent evaluation or the final toplevel build.

## Skipped Runtime Checks

- `systemctl --user restart quickshell.service` was not run because this environment is not the live Axiom Hyprland user session.
- `ii/shell.qml` runtime load was not checked because `origin/master` still lacks the end4 `ii` source tree; the RFC records this as prior-phase debt.
- Audio, brightness, network, Bluetooth, power-profile, tray, notification center, sidebar, overview, and launcher behavior were not exercised live because they require the graphical Axiom session and hardware devices.

## Conclusion

The repository-local validation is sufficient for this Phase 4 substrate PR. Remaining risk is live-session integration with the eventual end4 `ii` shell tree and hardware-backed controls.
