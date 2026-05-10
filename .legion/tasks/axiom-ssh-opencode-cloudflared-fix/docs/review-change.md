# Review Change: Axiom SSH Autossh and Opencode Cloudflared Fix

## Verdict

PASS with external follow-up.

## Blocking Findings

None.

## Scope Review

- In scope: `modules/xdg.nix` fixes the XDG SSH wrapper runtime path expansion.
- In scope: `hosts/azar/default.nix` adds a daemon-backed autossh reverse SSH tunnel on remote loopback port `2224` and disables socket-only OpenSSH activation.
- In scope: `hosts/axiom/default.nix` adds `opencode-server`, enables axiom cloudflared ingress for `opencode-axiom.0xc1.space`, and sets the agenix key path used by the encrypted tunnel credential.
- In scope: `modules/services/cloudflared.nix` changes the cloudflared secret group from a Darwin-only hard-coded `staff` to platform-specific `staff`/`users`, which is required by enabling the module on NixOS `axiom`.
- In scope: `hosts/axiom/secrets/cloudflared-credentials.age` is encrypted secret material; plaintext tunnel JSON remains under gitignored task runtime and is not part of the diff.

## Security Lens

Security review was applied because the change touches SSH access, Cloudflare tunnel routing, opencode exposure, and encrypted credentials.

- The opencode service binds only to `127.0.0.1:4096`; no direct LAN/public bind is introduced.
- The Cloudflare ingress points to the loopback service and the corrected DNS route `opencode-axiom.0xc1.space` was created.
- The tunnel credential is committed only as an age-encrypted file.
- Autossh remote forwarding binds remote loopback `127.0.0.1:2224`, not all remote interfaces.
- Cloudflare Access policy remains an external上线前置条件 and must be verified before treating the public hostname as safe for use.

## Verification Review

- `azar` targeted evals confirmed autossh command shape and no generated `sshd.socket`.
- `axiom` targeted evals confirmed opencode ExecStart, cloudflared config, corrected hostname, cloudflared secret group, and agenix sshKey path.
- Darwin `charlie` eval confirmed cloudflared secret group remains `staff`.
- Wrapped OpenSSH package build and generated wrapper inspection confirmed the literal `$XDG_CONFIG_HOME/ssh/config` bug is fixed.
- `nix build --impure --no-link` passed for both `axiom` and `azar` NixOS toplevels.

## Non-blocking Follow-up

- Delete the mistakenly created `axiom-opencode.0xc1.space` CNAME in Cloudflare DNS/Zero Trust; the cloudflared CLI used here exposes route create/overwrite, not delete.
- Create/verify the Cloudflare Access application and allow policy for `opencode-axiom.0xc1.space` before using the public endpoint.
- After deployment, smoke test `ssh azar`, `systemctl status autossh-reverse-ssh` on `azar`, and `systemctl status opencode-server cloudflared` on `axiom`.
