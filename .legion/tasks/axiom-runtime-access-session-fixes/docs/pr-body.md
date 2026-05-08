## Summary
- Make `axiom` run persistent `sshd.service` instead of socket-only OpenSSH activation so the autossh reverse tunnel has a daemon-backed local target.
- Keep the reverse tunnel on remote loopback `127.0.0.1:2223` and order/want autossh after `sshd.service`.
- Start Hyprland through the evaluated `start-hyprland` launcher path from greetd/UWSM instead of the warning-prone `hyprland-uwsm.desktop` path.

## Verification
- `nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; auto = c.systemd.services.autossh-reverse-ssh; greetd = c.services.greetd.settings.default_session.command; startup = c.home.dataFile."hey/hooks.d/startup.d/05-session".text; in { sshStartWhenNeeded = c.services.openssh.startWhenNeeded; sshdServiceExists = builtins.hasAttr "sshd" c.systemd.services; sshdSocketExists = builtins.hasAttr "sshd" c.systemd.sockets; autosshAfter = auto.after; autosshWants = auto.wants; autosshUser = auto.serviceConfig.User; tunnelExec = auto.serviceConfig.ExecStart; tunnelStillUses2223 = builtins.match ".*127[.]0[.]0[.]1:2223:127[.]0[.]0[.]1:22.*" auto.serviceConfig.ExecStart != null; tunnelStillTargetsRemote = builtins.match ".*root@8[.]159[.]128[.]125.*" auto.serviceConfig.ExecStart != null; greetdCommand = greetd; greetdUsesStartHyprland = builtins.match ".*/bin/start-hyprland.*" greetd != null; greetdUsesHyprlandUwsmDesktop = builtins.match ".*hyprland-uwsm[.]desktop.*" greetd != null; startupStartsSessionTarget = builtins.match ".*systemctl --user start hyprland-session[.]target.*" startup != null; preConfigHasStartupHook = builtins.match ".*exec-once = hey hook startup.*" c.home.configFile."hypr/hyprland.pre.conf".text != null; }'`
- `/nix/store/vral2gza5mjz6sc0z7b8vqjqyi2rdg3v-uwsm-0.24.3/bin/uwsm start -n -e -D Hyprland /nix/store/c3fib2ki5kzwzljmfqlkcfxad4d27asb-hyprland-0.53.3/bin/start-hyprland`
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`

## Risk / Follow-up
- Live remote SSH and physical display login were not run from this environment.
- After deployment, check `systemctl status sshd autossh-reverse-ssh`, verify remote `127.0.0.1:2223` is listening on `8.159.128.125`, and confirm the Hyprland warning is gone on physical login.

## Legion Evidence
- `.legion/tasks/axiom-runtime-access-session-fixes/plan.md`
- `.legion/tasks/axiom-runtime-access-session-fixes/docs/rfc.md`
- `.legion/tasks/axiom-runtime-access-session-fixes/docs/review-rfc.md`
- `.legion/tasks/axiom-runtime-access-session-fixes/docs/test-report.md`
- `.legion/tasks/axiom-runtime-access-session-fixes/docs/review-change.md`
- `.legion/tasks/axiom-runtime-access-session-fixes/docs/report-walkthrough.md`
