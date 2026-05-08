## Summary
- Add an `axiom` systemd autossh reverse SSH tunnel to `root@8.159.128.125`.
- Forward remote `127.0.0.1:2223` to `axiom` local `127.0.0.1:22`, avoiding `charlie`'s existing `2222` tunnel.
- Keep the change host-local; no SSH keys, remote server config, Cloudflare config, or `charlie` config are changed.

## Verification
- `nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; svc = c.systemd.services.autossh-reverse-ssh; execStart = svc.serviceConfig.ExecStart; in { inherit execStart; user = svc.serviceConfig.User; workingDirectory = svc.serviceConfig.WorkingDirectory; restart = svc.serviceConfig.Restart; restartSec = svc.serviceConfig.RestartSec; environment = svc.environment; after = svc.after; wants = svc.wants; wantedBy = svc.wantedBy; autosshInUserPackages = builtins.any (p: (p.pname or "") == "autossh") c.user.packages; hasRemoteForward = builtins.match ".*127[.]0[.]0[.]1:2223:127[.]0[.]0[.]1:22.*" execStart != null; hasRemoteTarget = builtins.match ".*root@8[.]159[.]128[.]125.*" execStart != null; hasLoopbackOnly = builtins.match ".*-R 127[.]0[.]0[.]1:2223:127[.]0[.]0[.]1:22.*" execStart != null; hasBatchMode = builtins.match ".*BatchMode=yes.*" execStart != null; }'`
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`

## Risk / Follow-up
- Live SSH through `8.159.128.125:2223` was not tested here; validate credentials, host-key trust, and remote port availability after deploying to physical `axiom`.

## Legion Evidence
- `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/plan.md`
- `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/rfc.md`
- `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/review-rfc.md`
- `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/test-report.md`
- `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/review-change.md`
- `.legion/tasks/axiom-autossh-reverse-ssh-tunnel/docs/report-walkthrough.md`
