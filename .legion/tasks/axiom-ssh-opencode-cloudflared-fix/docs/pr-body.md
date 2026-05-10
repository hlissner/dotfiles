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
