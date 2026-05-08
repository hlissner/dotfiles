# Test Report

## Summary

Result: PASS

The `axiom` system builds successfully, greetd now points at the evaluated Hyprland UWSM desktop entry, and network ownership is coherent for NetworkManager + iwd + resolved.

## Commands

### Axiom Toplevel Build

Command:

```sh
nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS

Evidence:

- Built `nixos-system-axiom-25.11.20260203.e576e3c` successfully.
- Build generated updated `greetd`, `iwd`, `NetworkManager-ensure-profiles`, system unit, etc, and system closures.
- Non-blocking pre-existing warnings remain: `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, future `i18n.inputMethod.enabled`, and renamed `system`.

Why this command was chosen:

- The previous portal regression was only caught by an actual `axiom` toplevel build, so this is the primary credibility gate for this runtime fix.

### Targeted Runtime State Evaluation

Command:

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; desktops = c.services.displayManager.sessionData.desktops; in { sessionCommand = c.services.greetd.settings.default_session.command; sessionNames = c.services.displayManager.sessionData.sessionNames; hyprlandUwsmDesktopExists = builtins.pathExists "${desktops}/share/wayland-sessions/hyprland-uwsm.desktop"; hyprlandDesktopExists = builtins.pathExists "${desktops}/share/wayland-sessions/hyprland.desktop"; networkManagerEnable = c.networking.networkmanager.enable; networkManagerBackend = c.networking.networkmanager.wifi.backend; networkManagerDns = c.networking.networkmanager.dns; iwdEnable = c.networking.wireless.iwd.enable; iwdNetworkConfiguration = c.networking.wireless.iwd.settings.General.EnableNetworkConfiguration; resolvedEnable = c.services.resolved.enable; dhcpcdEnable = c.networking.dhcpcd.enable; dhcpcdServiceExists = builtins.hasAttr "dhcpcd" c.systemd.services; networkManagerEnsureProfilesWantedBy = c.systemd.services."NetworkManager-ensure-profiles".wantedBy; wiredProfile = c.networking.networkmanager.ensureProfiles.profiles.enp14s0; }'
```

Result: PASS

Output:

```json
{
  "dhcpcdEnable": false,
  "dhcpcdServiceExists": false,
  "hyprlandDesktopExists": false,
  "hyprlandUwsmDesktopExists": true,
  "iwdEnable": true,
  "iwdNetworkConfiguration": false,
  "networkManagerBackend": "iwd",
  "networkManagerDns": "systemd-resolved",
  "networkManagerEnable": true,
  "networkManagerEnsureProfilesWantedBy": ["multi-user.target"],
  "resolvedEnable": true,
  "sessionCommand": "/nix/store/vral2gza5mjz6sc0z7b8vqjqyi2rdg3v-uwsm-0.24.3/bin/uwsm start -eD Hyprland hyprland-uwsm.desktop",
  "sessionNames": ["hyprland-uwsm", "steam"],
  "wiredProfile": {
    "connection": {
      "autoconnect": true,
      "id": "enp14s0",
      "interface-name": "enp14s0",
      "type": "ethernet"
    },
    "ipv4": { "method": "auto" },
    "ipv6": {
      "addr-gen-mode": "stable-privacy",
      "method": "auto"
    }
  }
}
```

Why this command was chosen:

- It directly checks the two user-reported failure modes: the missing desktop entry and network ownership/startup services.
- It proves `hyprland.desktop` is absent, `hyprland-uwsm.desktop` is present, and greetd now references the present entry.
- It proves NetworkManager remains enabled with the iwd backend and resolved DNS, iwd no longer owns DHCP/routes, and legacy `dhcpcd` is disabled/absent.

### Diff Hygiene

Command:

```sh
git diff --check
```

Result: PASS

Output: no whitespace errors.

## Skipped

- Runtime login and physical network tests were not run from this build environment. The closest available evidence is the evaluated closure/session data plus the actual `axiom` toplevel build.
