# Test Report: Axiom Autossh Reverse SSH Tunnel

## Verdict
PASS

## Summary
The generated `axiom` configuration contains the expected autossh reverse SSH tunnel service, keeps the remote bind address loopback-only on port `2223`, runs as local user `c1`, includes `autossh` in user packages, and the full `axiom` NixOS toplevel builds successfully.

## Commands

### Targeted service evaluation

```bash
nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; svc = c.systemd.services.autossh-reverse-ssh; execStart = svc.serviceConfig.ExecStart; in { inherit execStart; user = svc.serviceConfig.User; workingDirectory = svc.serviceConfig.WorkingDirectory; restart = svc.serviceConfig.Restart; restartSec = svc.serviceConfig.RestartSec; environment = svc.environment; after = svc.after; wants = svc.wants; wantedBy = svc.wantedBy; autosshInUserPackages = builtins.any (p: (p.pname or "") == "autossh") c.user.packages; hasRemoteForward = builtins.match ".*127[.]0[.]0[.]1:2223:127[.]0[.]0[.]1:22.*" execStart != null; hasRemoteTarget = builtins.match ".*root@8[.]159[.]128[.]125.*" execStart != null; hasLoopbackOnly = builtins.match ".*-R 127[.]0[.]0[.]1:2223:127[.]0[.]0[.]1:22.*" execStart != null; hasBatchMode = builtins.match ".*BatchMode=yes.*" execStart != null; }'
```

Result: PASS

Key output:

```json
{
  "autosshInUserPackages": true,
  "execStart": "/nix/store/6crrq71dral925qiy0kx7hcd9mfwb2lc-autossh-1.4g/bin/autossh -M 0 -N -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o BatchMode=yes -R 127.0.0.1:2223:127.0.0.1:22 root@8.159.128.125",
  "hasBatchMode": true,
  "hasLoopbackOnly": true,
  "hasRemoteForward": true,
  "hasRemoteTarget": true,
  "restart": "always",
  "restartSec": "10s",
  "user": "c1",
  "wantedBy": ["multi-user.target"],
  "wants": ["network-online.target"],
  "workingDirectory": "/home/c1"
}
```

### Full `axiom` build

```bash
nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS

Evidence:
- The build produced `unit-autossh-reverse-ssh.service.drv` and rebuilt the `axiom` system closure.
- The command exited successfully.

Warnings observed were pre-existing evaluation warnings about `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, deprecated `i18n.inputMethod.enabled`, and renamed `system`/`stdenv.hostPlatform.system`; none were introduced by this service change.

## Why These Checks
- The targeted eval directly proves the security-sensitive tunnel shape: loopback-only remote bind, port `2223`, remote target, user, environment, restart behavior, and package inclusion.
- The full build proves the host-level NixOS integration and catches generated systemd unit or closure issues.

## Not Run
- Live `ssh` through `8.159.128.125:2223` was not run because this environment does not deploy to physical `axiom` or validate the remote server state.
- Deployment-time validation must confirm that `axiom` has usable SSH credentials for `root@8.159.128.125`, the remote host trusts the host key path, and remote `127.0.0.1:2223` is free.
