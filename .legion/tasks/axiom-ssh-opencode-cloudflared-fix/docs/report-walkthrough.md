# Report Walkthrough: Axiom SSH Autossh and Opencode Cloudflared Fix

## Mode

implementation

## Summary

- Fixes the Linux XDG SSH wrapper so `ssh`/`scp` use the expanded `$XDG_CONFIG_HOME` path instead of passing a literal `$XDG_CONFIG_HOME/ssh/config` to OpenSSH.
- Adds a daemon-backed `azar` autossh reverse tunnel on remote loopback `127.0.0.1:2224`, mirroring the existing `charlie`/`axiom` access pattern without touching `charlie`.
- Adds `axiom` `opencode-server` as a systemd service bound to `127.0.0.1:4096`, creates a new `home-axiom` Cloudflare tunnel, and routes `opencode-axiom.0xc1.space` to it.

## What Changed

- `modules/xdg.nix`: changes wrapped `ssh`, `scp`, `ssh-add`, and `ssh-copy-id` to compute the XDG SSH directory at runtime and fall back to `$HOME/.config/ssh` when `XDG_CONFIG_HOME` is unset.
- `hosts/azar/default.nix`: adds `autossh`, forces persistent `sshd.service`, and adds `autossh-reverse-ssh` forwarding remote `127.0.0.1:2224` to local `127.0.0.1:22`.
- `hosts/axiom/default.nix`: adds `opencode-server`, enables axiom cloudflared config, sets tunnel id `bc8b3291-de93-4f7f-807a-23f802ef021f`, and uses hostname `opencode-axiom.0xc1.space`.
- `modules/services/cloudflared.nix`: makes cloudflared age secret group platform-specific: `staff` on Darwin, `users` on Linux.
- `hosts/axiom/secrets/cloudflared-credentials.age`: adds encrypted tunnel credentials; plaintext credentials were kept only in gitignored task runtime.

## Validation Evidence

- `docs/test-report.md`: targeted evals passed for the wrapper shape, `azar` autossh command/socket mode, `axiom` opencode command, `axiom` cloudflared config, secret groups, and axiom agenix key path.
- `docs/test-report.md`: `nix build --impure --no-link .#nixosConfigurations.azar.config.system.build.toplevel` passed.
- `docs/test-report.md`: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed after staging the new encrypted secret so the git-backed flake source includes it.
- `docs/test-report.md`: Cloudflare CLI created `home-axiom` tunnel and CNAME route for `opencode-axiom.0xc1.space`.
- `docs/review-change.md`: readiness/security review passed with no blocking findings.

## External Follow-up

- Delete the mistakenly created `axiom-opencode.0xc1.space` CNAME in Cloudflare DNS/Zero Trust.
- Create or verify Cloudflare Access application and allow policy for `opencode-axiom.0xc1.space` before using the public endpoint.
- After deployment, run `ssh azar`, `systemctl status autossh-reverse-ssh` on `azar`, and `systemctl status opencode-server cloudflared` on `axiom`.

## Key Evidence Files

- Plan: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/plan.md`
- RFC: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/rfc.md`
- RFC review: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/review-rfc.md`
- Verification: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/test-report.md`
- Change review: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/docs/review-change.md`
