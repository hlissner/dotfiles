# Test Report: Axiom Runtime Access And Session Fixes

## Verdict
PASS

## Summary
The generated `axiom` configuration now uses a persistent `sshd.service` instead of socket-only OpenSSH activation, and the autossh reverse tunnel service wants/orders after that daemon while preserving the remote loopback `2223` forward. The generated greetd/UWSM command now points at the evaluated `start-hyprland` path instead of `hyprland-uwsm.desktop`. The full `axiom` toplevel build succeeds.

## Commands

### Targeted generated-shape eval

```bash
nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; auto = c.systemd.services.autossh-reverse-ssh; greetd = c.services.greetd.settings.default_session.command; startup = c.home.dataFile."hey/hooks.d/startup.d/05-session".text; in { sshStartWhenNeeded = c.services.openssh.startWhenNeeded; sshdServiceExists = builtins.hasAttr "sshd" c.systemd.services; sshdSocketExists = builtins.hasAttr "sshd" c.systemd.sockets; autosshAfter = auto.after; autosshWants = auto.wants; autosshUser = auto.serviceConfig.User; tunnelExec = auto.serviceConfig.ExecStart; tunnelStillUses2223 = builtins.match ".*127[.]0[.]0[.]1:2223:127[.]0[.]0[.]1:22.*" auto.serviceConfig.ExecStart != null; tunnelStillTargetsRemote = builtins.match ".*root@8[.]159[.]128[.]125.*" auto.serviceConfig.ExecStart != null; greetdCommand = greetd; greetdUsesStartHyprland = builtins.match ".*/bin/start-hyprland.*" greetd != null; greetdUsesHyprlandUwsmDesktop = builtins.match ".*hyprland-uwsm[.]desktop.*" greetd != null; startupStartsSessionTarget = builtins.match ".*systemctl --user start hyprland-session[.]target.*" startup != null; preConfigHasStartupHook = builtins.match ".*exec-once = hey hook startup.*" c.home.configFile."hypr/hyprland.pre.conf".text != null; }'
```

Result: PASS

Key output:

```json
{
  "autosshAfter": ["network-online.target", "sshd.service"],
  "autosshUser": "c1",
  "autosshWants": ["network-online.target", "sshd.service"],
  "greetdCommand": "/nix/store/vral2gza5mjz6sc0z7b8vqjqyi2rdg3v-uwsm-0.24.3/bin/uwsm start -eD Hyprland /nix/store/c3fib2ki5kzwzljmfqlkcfxad4d27asb-hyprland-0.53.3/bin/start-hyprland",
  "greetdUsesHyprlandUwsmDesktop": false,
  "greetdUsesStartHyprland": true,
  "preConfigHasStartupHook": true,
  "sshStartWhenNeeded": false,
  "sshdServiceExists": true,
  "sshdSocketExists": false,
  "startupStartsSessionTarget": true,
  "tunnelStillTargetsRemote": true,
  "tunnelStillUses2223": true
}
```

### UWSM dry run for new command shape

```bash
/nix/store/vral2gza5mjz6sc0z7b8vqjqyi2rdg3v-uwsm-0.24.3/bin/uwsm start -n -e -D Hyprland /nix/store/c3fib2ki5kzwzljmfqlkcfxad4d27asb-hyprland-0.53.3/bin/start-hyprland
```

Result: PASS

Key output:

```text
Selected compositor ID: start-hyprland
Command Line: /nix/store/c3fib2ki5kzwzljmfqlkcfxad4d27asb-hyprland-0.53.3/bin/start-hyprland
Will start start-hyprland...
Dry Run Mode. Will not go further.
```

The command also reported an already active compositor/session in this local environment, which is expected for dry-run validation and not a failure.

### Full `axiom` build

```bash
nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS

Evidence:
- Build generated `unit-sshd.service.drv`, `unit-autossh-reverse-ssh.service.drv`, updated `greetd.toml`, and the `axiom` system closure.
- The command exited successfully.

Warnings observed were pre-existing eval warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, deprecated `i18n.inputMethod.enabled`, and renamed `system`/`stdenv.hostPlatform.system`.

## Why These Checks
- The targeted eval directly proves the SSH activation mode, reverse tunnel dependencies, unchanged remote-forward shape, and Hyprland startup command.
- The UWSM dry run proves the new command resolves to `start-hyprland` rather than direct `Hyprland`.
- The full build proves NixOS integration and catches generated unit/config errors.

## Not Run
- Live reverse SSH through `8.159.128.125:2223` was not run from this environment.
- Physical login on `axiom` was not run from this environment.

After deploying this change to physical `axiom`, validate:
- `systemctl status sshd autossh-reverse-ssh`
- On `8.159.128.125`, check that remote `127.0.0.1:2223` is listening.
- Log in graphically and confirm the Hyprland `start-hyprland` warning is gone.
