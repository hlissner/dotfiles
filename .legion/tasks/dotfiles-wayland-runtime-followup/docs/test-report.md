# Test Report

## Summary

Result: PASS

`axiom` builds successfully, the combined Hyprland config parses under the evaluated Hyprland 0.53.3 binary, deprecated `windowrulev2` is absent, and NetworkManager no longer carries the `no-auto-default=*` setting that could block fallback default connection creation.

## Commands

### Axiom Toplevel Build

Command:

```sh
nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS

Evidence:

- Built `nixos-system-axiom-25.11.20260203.e576e3c` successfully.
- Build regenerated Hyprland home config, NetworkManager config, NetworkManager service units, and the `axiom` system closure.
- Non-blocking pre-existing warnings remain: `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, future `i18n.inputMethod.enabled`, and renamed `system`.

Why this command was chosen:

- It is the strongest local validation gate for `axiom` system integration and catches generated unit/config failures that pure evals can miss.

### Hyprland Config Parser

Command:

```sh
full=$(nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake (toString ./.); c = flake.nixosConfigurations.axiom.config; pkgs = flake.nixosConfigurations.axiom.pkgs; base = builtins.replaceStrings [ "source = ~/.config/hypr/hyprland.pre.conf\n" "source = ~/.config/hypr/hyprland.post.conf\n" ] [ "" "" ] (builtins.readFile ./config/hypr/hyprland.conf); in pkgs.writeText "hyprland-full.conf" (c.home.configFile."hypr/hyprland.pre.conf".text + "\n" + base + "\n" + c.home.configFile."hypr/hyprland.post.conf".text)') && /nix/store/c3fib2ki5kzwzljmfqlkcfxad4d27asb-hyprland-0.53.3/bin/Hyprland --verify-config --config "$full"
```

Result: PASS

Output summary:

```text
Config parsing result:

config ok
```

Why this command was chosen:

- Build/eval do not parse Hyprland rule syntax. `Hyprland --verify-config` directly exercises the parser that reported the runtime syntax errors.
- The command verifies the combined effective config: generated pre config, checked-in base config, and generated post/theme config.

### Targeted Effective State Eval

Command:

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; pre = c.home.configFile."hypr/hyprland.pre.conf".text; post = c.home.configFile."hypr/hyprland.post.conf".text; in { hyprlandVersion = c.programs.hyprland.package.version; hasWindowrulev2 = builtins.match ".*windowrulev2.*" pre != null || builtins.match ".*windowrulev2.*" (builtins.readFile ./config/hypr/hyprland.conf) != null; generatedPreContainsWindowrule = builtins.match ".*windowrule = match:class.*" pre != null; generatedPreContainsOldLayerRule = builtins.match ".*layerrule = noanim,.*" pre != null; networkManagerEnable = c.networking.networkmanager.enable; networkManagerBackend = c.networking.networkmanager.wifi.backend; networkManagerDns = c.networking.networkmanager.dns; noAutoDefaultSet = if c.networking.networkmanager.settings ? main then c.networking.networkmanager.settings.main ? "no-auto-default" else false; iwdEnable = c.networking.wireless.iwd.enable; iwdNetworkConfiguration = c.networking.wireless.iwd.settings.General.EnableNetworkConfiguration; resolvedEnable = c.services.resolved.enable; dhcpcdEnable = c.networking.dhcpcd.enable; dhcpcdServiceExists = builtins.hasAttr "dhcpcd" c.systemd.services; wiredProfile = c.networking.networkmanager.ensureProfiles.profiles.enp14s0; }'
```

Result: PASS

Output:

```json
{
  "dhcpcdEnable": false,
  "dhcpcdServiceExists": false,
  "generatedPreContainsOldLayerRule": false,
  "generatedPreContainsWindowrule": true,
  "hasWindowrulev2": false,
  "hyprlandVersion": "0.53.3",
  "iwdEnable": true,
  "iwdNetworkConfiguration": false,
  "networkManagerBackend": "iwd",
  "networkManagerDns": "systemd-resolved",
  "networkManagerEnable": true,
  "noAutoDefaultSet": false,
  "resolvedEnable": true,
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

- It directly checks that deprecated rule syntax is gone and that the current network ownership model is effective.
- It specifically proves NetworkManager can create default connections again because `no-auto-default` is no longer set.

### Generated NetworkManager Config

Command:

```sh
nix eval --impure --raw '.#nixosConfigurations.axiom.config.environment.etc."NetworkManager/NetworkManager.conf".source'
```

Result: PASS

Generated config excerpt:

```ini
[device]
wifi.backend=iwd
wifi.scan-rand-mac-address=yes

[main]
dhcp=internal
dns=systemd-resolved
plugins=keyfile
rc-manager=unmanaged
```

`no-auto-default=*` is absent.

### Legacy Syntax Search

Command:

```sh
grep-equivalent search for old Hyprland syntax across `*.nix` and `*.conf`
```

Result: PASS

Evidence: no `windowrulev2`, old layer-rule spellings, old event/effect spellings, or `workspace_swipe` matches remain in active Nix/Hyprland config files.

### Diff Hygiene

Command:

```sh
git diff --check
```

Result: PASS

Output: no whitespace errors.

## Skipped

- Physical login and network tests were not run on `axiom` from this environment. The available validation proves generated config, parser compatibility, and system build behavior.
