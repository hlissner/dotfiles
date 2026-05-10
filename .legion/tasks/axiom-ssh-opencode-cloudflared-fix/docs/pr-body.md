## Summary

- Fix the Linux XDG SSH wrapper so OpenSSH receives the expanded XDG config path instead of a literal `$XDG_CONFIG_HOME/ssh/config`.
- Add `azar` autossh reverse SSH on remote loopback port `2224` with persistent `sshd.service`.
- Add `axiom` systemd `opencode-server`, create/wire the `home-axiom` Cloudflare tunnel, and route `opencode-axiom.0xc1.space` to `127.0.0.1:4096`.

## Validation

- `nix build --impure --no-link .#nixosConfigurations.azar.config.system.build.toplevel`
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- Targeted Nix evals for SSH wrapper shape, autossh service, opencode service, cloudflared config, secret groups, and agenix key path.
- Cloudflare CLI created tunnel `home-axiom` (`bc8b3291-de93-4f7f-807a-23f802ef021f`) and DNS route `opencode-axiom.0xc1.space`.

## Follow-up

- Delete the accidentally created `axiom-opencode.0xc1.space` CNAME in Cloudflare.
- Verify Cloudflare Access policy for `opencode-axiom.0xc1.space` before using the public endpoint.

## Runtime Follow-up

- Fix Linux cloudflared config generation to use `/etc/cloudflared/config.yml` instead of Home Manager linking `/home/c1/.cloudflared/config.yml`, because the agenix credential path makes that directory root-owned before Home Manager activation.
- Validate that `cloudflared.service` points at `/etc/cloudflared/config.yml`, Linux no longer has a home-managed cloudflared config file, Darwin `charlie` still does, and the `axiom` toplevel builds.
