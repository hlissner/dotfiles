# Test Report: Axiom SSH Autossh and Opencode Cloudflared Fix

## Summary

PASS with external follow-up. Local Nix evaluation/build checks passed for the SSH wrapper shape, `azar` autossh service, `axiom` opencode service, `axiom` cloudflared config, and both affected NixOS toplevel builds. Cloudflare tunnel creation and the corrected DNS route also succeeded. Live deployment checks and Cloudflare Access policy remain external/manual.

## Commands and Results

- `nix build --impure --no-link --print-out-paths --expr 'let flake = builtins.getFlake "path:/home/c1/dotfiles/.worktrees/axiom-ssh-opencode-cloudflared-fix"; packages = flake.nixosConfigurations.azar.config.environment.systemPackages; in builtins.elemAt (builtins.filter (p: builtins.match ".*openssh.*wrapped.*" p.name != null) packages) 0'`
  - Result: PASS.
  - Evidence: built wrapped OpenSSH package `/nix/store/yrdr4xzkxsa2939p89lhdzzglidda8l2--nix-store-9ng738k8rbl6n6yz0x20kxnfxzhlns0c-openssh-10.2p1-wrapped`.

- Read generated wrapper `/nix/store/yrdr4xzkxsa2939p89lhdzzglidda8l2--nix-store-9ng738k8rbl6n6yz0x20kxnfxzhlns0c-openssh-10.2p1-wrapped/bin/ssh`.
  - Result: PASS.
  - Evidence: wrapper now computes `dir="$XDG_CONFIG_HOME/ssh"`, falls back to `$HOME/.config/ssh`, computes `cfg="$dir/config"`, and passes `opts=(-F "$cfg")` only when the config file is non-empty.

- `nix eval --impure --raw .#nixosConfigurations.azar.config.systemd.services.autossh-reverse-ssh.serviceConfig.ExecStart`
  - Result: PASS.
  - Evidence: command contains `-R 127.0.0.1:2224:127.0.0.1:22 root@8.159.128.125` with autossh keepalive and `ExitOnForwardFailure=yes`.

- `nix eval --impure .#nixosConfigurations.azar.config --apply 'cfg: cfg.systemd.sockets ? sshd'`
  - Result: PASS.
  - Evidence: returned `false`, confirming `azar` no longer generates `sshd.socket` for socket activation.

- `nix eval --impure --raw .#nixosConfigurations.axiom.config.systemd.services.opencode-server.serviceConfig.ExecStart`
  - Result: PASS.
  - Evidence: returned `/home/c1/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096`.

- `nix eval --impure --raw .#nixosConfigurations.axiom.config --apply 'cfg: cfg.home.file.".cloudflared/config.yml".text'`
  - Result: PASS.
  - Evidence: generated config includes tunnel `bc8b3291-de93-4f7f-807a-23f802ef021f`, `tunnelName` `home-axiom`, and ingress hostname `opencode-axiom.0xc1.space` to `http://127.0.0.1:4096`.

- `nix eval --impure .#nixosConfigurations.axiom.config.age.secrets.cloudflared-credentials.group`
  - Result: PASS.
  - Evidence: returned `"users"`.

- `nix eval --impure .#darwinConfigurations.charlie.config.age.secrets.cloudflared-credentials.group`
  - Result: PASS.
  - Evidence: returned `"staff"`, preserving Darwin behavior.

- `nix eval --impure --raw .#nixosConfigurations.axiom.config.modules.agenix.sshKey`
  - Result: PASS.
  - Evidence: returned `/etc/ssh/ssh_host_ed25519_key`, matching the OpenSSH host key path and the recipient used for the encrypted cloudflared credential.

- `HOME="$PWD/.legion/tasks/axiom-ssh-opencode-cloudflared-fix/runtime/cloudflared-home" nix run nixpkgs#cloudflared -- tunnel create home-axiom`
  - Result: PASS.
  - Evidence: created tunnel `home-axiom` with id `bc8b3291-de93-4f7f-807a-23f802ef021f`.

- `HOME="$PWD/.legion/tasks/axiom-ssh-opencode-cloudflared-fix/runtime/cloudflared-home" nix run nixpkgs#cloudflared -- tunnel route dns home-axiom opencode-axiom.0xc1.space`
  - Result: PASS.
  - Evidence: CLI reported that CNAME `opencode-axiom.0xc1.space` routes to tunnel `bc8b3291-de93-4f7f-807a-23f802ef021f`.

- `nix run nixpkgs#age -- -e -R /etc/ssh/ssh_host_ed25519_key.pub -o hosts/axiom/secrets/cloudflared-credentials.age <runtime tunnel json>`
  - Result: PASS.
  - Evidence: encrypted age file exists at `hosts/axiom/secrets/cloudflared-credentials.age`; plaintext tunnel JSON remains only under gitignored task runtime.

- `nix build --impure --no-link .#nixosConfigurations.azar.config.system.build.toplevel`
  - Result: PASS.
  - Evidence: built `nixos-system-azar-25.11.20260203.e576e3c`.

- `git add hosts/axiom/secrets/cloudflared-credentials.age && nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
  - Result: PASS.
  - Evidence: built `nixos-system-axiom-25.11.20260203.e576e3c`.
  - Note: staging the new encrypted secret was required because git-backed flake evaluation does not include untracked files.

## Resolved Failures During Verification

- Initial `axiom` build failed because `modules.agenix.sshKey` defaulted to `/etc/ssh/host_ed25519`, which did not exist in this environment. Implementation now sets `modules.agenix.sshKey = "/etc/ssh/ssh_host_ed25519_key"` for `axiom`, matching the configured OpenSSH host key path and the cloudflared credential recipient.
- Initial `axiom` build after that failed because the new encrypted secret was untracked and omitted by git-backed flake evaluation. Staging `hosts/axiom/secrets/cloudflared-credentials.age` fixed the build input.
- The first Cloudflare DNS route was created with the mistaken hostname `axiom-opencode.0xc1.space`. The corrected route `opencode-axiom.0xc1.space` was created successfully. The mistaken CNAME still needs manual deletion in Cloudflare because `cloudflared tunnel route dns` exposes create/overwrite but not delete.

## Skipped / External Validation

- Live `ssh azar` after deployment was not run because this task has not deployed to physical `azar`.
- Live `systemctl status autossh-reverse-ssh` on `azar` and `systemctl status opencode-server cloudflared` on `axiom` were not run because deployment was not performed.
- Cloudflare Access application and allow policy for `opencode-axiom.0xc1.space` were not verified in the console. This remains an上线前置条件.
- The mistaken `axiom-opencode.0xc1.space` CNAME should be deleted manually in Cloudflare DNS/Zero Trust.

## Why These Checks

The targeted evals prove each generated service/config boundary directly, while the two NixOS toplevel builds prove the affected hosts can evaluate and build with the combined changes. External runtime checks remain separate because they depend on deployment, remote SSH auth, remote port availability, Cloudflare account state, and Cloudflare Access policy.

## Runtime Follow-up: cloudflared config path fix

### Problem Found After Deployment

- `systemctl is-active cloudflared opencode-server`
  - Result: `cloudflared` was `activating`; `opencode-server` was `active`.
- `journalctl -u cloudflared -n 80 --no-pager`
  - Result: FAIL before this follow-up.
  - Evidence: repeated `open /home/c1/.cloudflared/config.yml: no such file or directory` with restart loop.
- `journalctl -u home-manager-c1 -n 80 --no-pager`
  - Result: showed root cause.
  - Evidence: `ln: failed to create symbolic link '/home/c1/.cloudflared/config.yml': Permission denied`.
- `stat -c '%U:%G %a %n' /home/c1/.cloudflared /home/c1/.cloudflared/bc8b3291-de93-4f7f-807a-23f802ef021f.json`
  - Result: `/home/c1/.cloudflared` was `root:root 755`; Home Manager running as `c1` could not create `config.yml` there.

### Fix Validation

- `nix eval --impure --raw .#nixosConfigurations.axiom.config.systemd.services.cloudflared.serviceConfig.ExecStart`
  - Result: PASS.
  - Evidence: service now runs cloudflared with `--config /etc/cloudflared/config.yml`.
- `nix eval --impure --raw .#nixosConfigurations.axiom.config --apply 'cfg: cfg.environment.etc."cloudflared/config.yml".text'`
  - Result: PASS.
  - Evidence: system-owned config contains tunnel `bc8b3291-de93-4f7f-807a-23f802ef021f`, hostname `opencode-axiom.0xc1.space`, and service `http://127.0.0.1:4096`.
- `nix eval --impure .#nixosConfigurations.axiom.config --apply 'cfg: cfg.home.file ? ".cloudflared/config.yml"'`
  - Result: PASS.
  - Evidence: returned `false`; Linux no longer asks Home Manager to link `~/.cloudflared/config.yml`.
- `nix eval --impure --json .#darwinConfigurations.charlie.config --apply 'cfg: cfg.home.file.".cloudflared/config.yml".text'`
  - Result: PASS.
  - Evidence: Darwin `charlie` still gets its home-managed cloudflared config text.
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
  - Result: PASS.
  - Evidence: built `nixos-system-axiom-25.11.20260203.e576e3c` with generated `etc-cloudflared-config.yml` and updated `cloudflared.service`.

### Deployment Attempt

- `sudo -n true`
  - Result: BLOCKED.
  - Evidence: `sudo: 需要密码`.
- `hey sync axiom`
  - Result: BLOCKED in the automation shell.
  - Evidence: failed before deployment with `error: Invalid XDG directory: runtime`.

The declarative fix is validated, but live service recovery still requires a root-authorized switch/restart on `axiom`.
